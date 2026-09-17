-- FlightSim brake system v0.8
-- Simulation approximation: toe/parking brakes, autobrake, hydraulic availability,
-- wheel-slip protection and brake temperature.
-- Brake pressure is normalized 0..1; wheel pressure is exposed separately.
local Brakes={}; Brakes.__index=Brakes
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function pressure(system)
 if type(system)=="table" then return math.max(tonumber(system.Pressure) or 0,0) end
 return math.max(tonumber(system) or 0,0)
end
local function autobrakeLevel(mode)
 mode=string.upper(tostring(mode or "OFF"))
 if mode=="LOW" or mode=="1" then return 0.20 end
 if mode=="MED" or mode=="2" then return 0.35 end
 if mode=="HIGH" or mode=="3" then return 0.55 end
 if mode=="MAX" or mode=="RTO" then return 1.0 end
 return 0
end
function Brakes.new(state) return setmetatable({state=state},Brakes) end
function Brakes:Step(dt)
 local x=self.state:Get(); local b=x.Brakes or {}; x.Brakes=b; local h=x.Hydraulic or {}; dt=math.max(tonumber(dt) or 0,0)
 local failures=x.FailureEffects or {}
 local pressureA=failures.HydraulicAFailed==true and 0 or pressure(h.A)
 local pressureB=failures.HydraulicBFailed==true and 0 or pressure(h.B)
 local hydraulic=math.max(pressureA,pressureB)
 local available=clamp(hydraulic/1800,0,1)
 local gear=x.GearStatus or {}; local wheelContact=x.GroundContact==true and gear.DownLocked==true
 local toe=clamp(tonumber(b.ToeBrake) or 0,0,1)
 local parking=b.Parking==true and wheelContact and 1 or 0
 local autoTarget=0
 if b.AutobrakeArmed==true and wheelContact and math.max(tonumber(x.Airspeed) or 0,0)>20 then
  autoTarget=autobrakeLevel(b.AutobrakeMode)
 end
 b.AutobrakeActive=autoTarget>0
 local commanded=math.max(toe,parking,autoTarget)
 -- Demand is the requested braking load, not achieved hydraulic pressure.
 -- Keeping it pressure-independent prevents a failed hydraulic system from self-recovering through feedback.
 local target=commanded*available
 local current=clamp(tonumber(b.BrakePressure) or 0,0,1)
 b.BrakePressure=clamp(current+(target-current)*math.min(1,8*dt),0,1)

 local speed=math.max(tonumber(x.Airspeed) or 0,0)
 local antiSkid=b.AntiSkid~=false
 local leftWheel=math.max(tonumber(b.LeftWheelSpeed) or 0,0)
 local rightWheel=math.max(tonumber(b.RightWheelSpeed) or 0,0)
 local slipProtection=1
 local antiSkidActive=false
 -- Do not invent slip from airspeed alone. Use wheel-speed feedback when the physics layer provides it.
 if antiSkid and speed>8 and (leftWheel>0 or rightWheel>0) then
  local leftSlip=leftWheel>0 and clamp(leftWheel/speed,0,1) or 1
  local rightSlip=rightWheel>0 and clamp(rightWheel/speed,0,1) or 1
  slipProtection=math.min(1,leftSlip,rightSlip)
  antiSkidActive=slipProtection<0.95
 end
 local wheelPressure=b.BrakePressure*slipProtection
 b.LeftPressure=wheelPressure; b.RightPressure=wheelPressure
 b.AntiSkid=antiSkid; b.AntiSkidActive=antiSkidActive
 b.HydraulicAvailable=available>0.05; b.ParkingApplied=parking>0; b.BrakeDemand=commanded
 -- Thermal approximation: braking energy raises temperature; cooling is proportional to temperature excess.
 local heatInput=wheelPressure*speed*18*dt
 local cooling=(math.max(tonumber(b.BrakeTemperatureLeft) or 20,20)-20)*0.015*dt
 b.BrakeTemperatureLeft=clamp((tonumber(b.BrakeTemperatureLeft) or 20)+heatInput-cooling,20,1200)
 local coolingR=(math.max(tonumber(b.BrakeTemperatureRight) or 20,20)-20)*0.015*dt
 b.BrakeTemperatureRight=clamp((tonumber(b.BrakeTemperatureRight) or 20)+heatInput-coolingR,20,1200)
 b.BrakeOverheat=(b.BrakeTemperatureLeft>=450 or b.BrakeTemperatureRight>=450)
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.Brakes=commanded
end
return Brakes
