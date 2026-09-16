-- FlightSim cabin pressurization system v0.1
-- Game-simulation model; values are intentionally tunable and are not certified aircraft data.
local Pressurization={}; Pressurization.__index=Pressurization
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function ensure(x)
 x.Pressurization=x.Pressurization or {CabinAltitudeFt=0,CabinAltitudeRateFpm=0,DifferentialPsi=0,OutflowValve=0.35,Auto=true,ManualCommand=0.35,LandingAltitudeFt=0,Pack1Available=false,Pack2Available=false,BleedSource1=false,BleedSource2=false,SourceAvailable=false,Warning=false,CabinAltitudeWarning=false,DifferentialWarning=false,Dump=false,ReliefActive=false}
 local p=x.Pressurization
 p.Auto=p.Auto~=false; p.OutflowValve=clamp(tonumber(p.OutflowValve) or 0.35,0,1); p.ManualCommand=clamp(tonumber(p.ManualCommand) or p.OutflowValve,0,1); return p
end
function Pressurization.new(state) return setmetatable({state=state},Pressurization) end
function Pressurization:SetMode(auto) local p=ensure(self.state:Get()); p.Auto=auto==true; return true end
function Pressurization:SetOutflow(value) value=tonumber(value); if not finite(value) then return false,"invalid_outflow" end; local p=ensure(self.state:Get()); p.ManualCommand=clamp(value,0,1); if not p.Auto then p.OutflowValve=p.ManualCommand end; return true end
function Pressurization:SetLandingAltitude(value) value=tonumber(value); if not finite(value) then return false,"invalid_landing_altitude" end; ensure(self.state:Get()).LandingAltitudeFt=clamp(value,-2000,12000); return true end
function Pressurization:Step(dt)
 local x=self.state:Get(); local p=ensure(x); dt=math.max(0,tonumber(dt) or 0)
 local e1=x.Engines and x.Engines[1] or {}; local e2=x.Engines and x.Engines[2] or {}; local apu=x.APU or {}; local el=x.Electrical or {}
 local failed=(x.Failures and x.Failures.Engines) or {}
 p.Pack1Available=(e1.Running==true and not (failed[1] and failed[1].Active)) or (apu.Running==true and (el.Bus1==true or el.Bus2==true))
 p.Pack2Available=(e2.Running==true and not (failed[2] and failed[2].Active)) or (apu.Running==true and (el.Bus1==true or el.Bus2==true))
 p.BleedSource1=e1.Running==true and p.Pack1Available
 p.BleedSource2=e2.Running==true and p.Pack2Available
 p.SourceAvailable=p.Pack1Available or p.Pack2Available
 local aircraftAlt=math.max(0,tonumber(x.Altitude) or 0)
 local targetCabin=math.min(aircraftAlt,8000)
 if p.LandingAltitudeFt>0 and aircraftAlt<10000 then targetCabin=math.min(targetCabin,math.max(0,p.LandingAltitudeFt+500)) end
 if p.Dump then targetCabin=aircraftAlt end
 local sourceFactor=p.SourceAvailable and 1 or 0
 local desiredValve=p.Auto and clamp(0.25+(targetCabin/8000)*0.35+(1-sourceFactor)*0.35,0,1) or p.ManualCommand
 if not p.SourceAvailable then desiredValve=1 end
 p.OutflowValve=p.OutflowValve+(desiredValve-p.OutflowValve)*clamp(dt*0.8,0,1)
 local leakRate=35+95*p.OutflowValve
 local sourceRate=p.SourceAvailable and 85 or 0
 local targetRate=(targetCabin-p.CabinAltitudeFt)*0.015
 local rate=clamp(targetRate+leakRate-sourceRate,-1500,1500)
 if not p.SourceAvailable then rate=math.max(rate,120) end
 p.CabinAltitudeRateFpm=rate
 p.CabinAltitudeFt=clamp(p.CabinAltitudeFt+rate*dt/60,0,aircraftAlt+500)
 local cabinPressureAlt=p.CabinAltitudeFt
 p.DifferentialPsi=clamp((aircraftAlt-cabinPressureAlt)*0.00038,0,9.5)
 p.CabinAltitudeWarning=cabinPressureAlt>=10000
 p.DifferentialWarning=p.DifferentialPsi>=8.5
 p.ReliefActive=p.DifferentialPsi>=8.6
 if p.ReliefActive then p.OutflowValve=math.max(p.OutflowValve,0.9) end
 p.Warning=p.CabinAltitudeWarning or p.DifferentialWarning or (not p.SourceAvailable and aircraftAlt>5000)
 x.Pressurization=p
end
return Pressurization
