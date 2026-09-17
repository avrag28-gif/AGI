-- FlightSim engine runtime module v1.3
-- Simulation approximation. FuelFlow is expressed as kg/min and is consumed by Fuel.lua.
-- CFM56-7B26 thrust rating is aircraft-profile data; the performance curve is simulator tuning.
local Config=require(script.Parent.Config)
local Atmosphere=require(script.Parent.Atmosphere)
local Engine={}; Engine.__index=Engine
local function approach(v,t,r,dt) local d=t-v; local s=math.max(0,r)*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v,d) v=tonumber(v); return (v and v==v and v~=math.huge and v~=-math.huge) and v or d end
local function thrustAvailableFactor(altitudeFt,ambientTempC,mach)
 local altitude=clamp(math.max(0,altitudeFt)/41000,0,1); local isa=Atmosphere.ISATemperatureC(altitudeFt)
 local pressureFactor=math.exp(-1.15*altitude); local hotPenalty=clamp(1-math.max(0,ambientTempC-isa)*0.006,0.72,1); local coldBenefit=clamp(1+math.max(0,isa-ambientTempC)*0.0015,0.97,1.04); local ram=clamp(1+clamp(mach,0,0.82)*0.12,1,1.10)
 return clamp(pressureFactor*hotPenalty*coldBenefit*ram,0.18,1.05)
end
function Engine.new(state) return setmetatable({state=state},Engine) end
function Engine:Step(dt)
 local x=self.state:Get(); local electrical=((x.Electrical or {}).Bus1==true) or ((x.Electrical or {}).Bus2==true); local fuelSystem=x.FuelSystem or {}; local failures=x.Failures and x.Failures.Engines or {}; local antiIce=x.AntiIce or {}; local environment=x.Environment or {}; local weather=x.WeatherEffects or {}; local altitudeFt=math.max(0,finite(x.Altitude,0))
 local ambientTempC=finite(environment.TemperatureC,finite(weather.TemperatureC,Atmosphere.ISATemperatureC(altitudeFt))); local atm=Atmosphere.State(altitudeFt,ambientTempC); local mach=clamp(finite(x.Mach,finite(x.Airspeed,0)/math.max(atm.SpeedOfSoundKts,1)),0,0.90); local availableFactor=thrustAvailableFactor(altitudeFt,ambientTempC,mach)
 x.Mach=mach; x.AirDensityKgM3=atm.DensityKgM3
 for index=1,2 do
  local e=x.Engines[index]; local failure=failures[index]; local throttle=clamp(finite((x.Throttle or {})[index],0),0,1); local fuelAvailable=finite((x.Fuel or {}).Total,0)>0; local fuelPathAvailable=fuelSystem.EngineFuelAvailable~=nil and fuelSystem.EngineFuelAvailable[index]==true
  if failure and failure.Active then e.FuelOn=false; e.Ignition=false; e.Starter=false; e.Running=false; e.StartFailed=false end
  local usable=not(failure and failure.Active)
  if usable and e.Starter and electrical and not e.Running then e.N2=approach(e.N2,25,22,dt) else e.N2=approach(e.N2,e.Running and (55+35*throttle) or 0,e.Running and 12 or 5,dt) end
  if usable and not e.Running and e.Starter and e.FuelOn and e.Ignition and electrical and fuelAvailable and fuelPathAvailable and e.N2>=Config.StartN2 then e.Running=true; e.StartFailed=false end
  if usable and not e.Running and e.Starter and e.FuelOn and e.Ignition and (not electrical or not fuelAvailable or not fuelPathAvailable) then e.StartFailed=true end
  if usable and e.Running and (not e.FuelOn or not fuelAvailable or not fuelPathAvailable) then e.Running=false; e.Starter=false end
  if usable and e.Running then
   local targetN1=18+82*throttle; local targetN2=58+34*throttle; e.N1=approach(e.N1,targetN1,18,dt); e.N2=approach(e.N2,targetN2,10,dt); local targetEGT=360+360*throttle+math.max(0,throttle-0.9)*120; e.EGT=approach(e.EGT,targetEGT,220,dt); e.OilPressure=approach(e.OilPressure,35+60*(e.N2/100),55,dt)
   local n1Fraction=clamp(e.N1/100,0,1); e.FuelFlow=18+90*(n1Fraction^1.35)*(0.65+0.35*throttle); local penalty=clamp(finite(antiIce.EnginePenalty and antiIce.EnginePenalty[index],1),0.85,1); local ratedThrust=Config.MaxThrust/2; e.AvailableThrustFactor=availableFactor; e.Thrust=(e.N1/100)*ratedThrust*availableFactor*penalty; e.GeneratorAvailable=e.N2>=50
  else
   e.N1=approach(e.N1,0,18,dt); e.EGT=approach(e.EGT,20,120,dt); e.OilPressure=approach(e.OilPressure,0,45,dt); e.FuelFlow=0; e.Thrust=0; e.AvailableThrustFactor=availableFactor; e.GeneratorAvailable=false; if e.StartFailed and e.N2<8 then e.Starter=false end
  end
  if e.Running and e.N2>=46 then e.Starter=false end
 end
end
return Engine
