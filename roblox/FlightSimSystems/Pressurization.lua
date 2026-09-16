-- FlightSim cabin pressurization system v0.3
-- Game-simulation model; values are intentionally tunable and are not certified aircraft data.
local Pressurization={}; Pressurization.__index=Pressurization
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function ensure(x)
 x.Pressurization=x.Pressurization or {}
 local p=x.Pressurization; p.CabinAltitudeFt=tonumber(p.CabinAltitudeFt) or 0; p.CabinAltitudeRateFpm=tonumber(p.CabinAltitudeRateFpm) or 0; p.DifferentialPsi=tonumber(p.DifferentialPsi) or 0; p.Auto=p.Auto~=false; p.OutflowValve=clamp(tonumber(p.OutflowValve) or 0.35,0,1); p.ManualCommand=clamp(tonumber(p.ManualCommand) or p.OutflowValve,0,1); p.LandingAltitudeFt=tonumber(p.LandingAltitudeFt) or 0; p.Pack1Available=p.Pack1Available==true; p.Pack2Available=p.Pack2Available==true; p.BleedSource1=p.BleedSource1==true; p.BleedSource2=p.BleedSource2==true; p.SourceAvailable=p.SourceAvailable==true; p.Warning=p.Warning==true; p.CabinAltitudeWarning=p.CabinAltitudeWarning==true; p.DifferentialWarning=p.DifferentialWarning==true; p.Dump=p.Dump==true; p.ReliefActive=p.ReliefActive==true; return p
end
function Pressurization.new(state) return setmetatable({state=state},Pressurization) end
function Pressurization:SetMode(auto) ensure(self.state:Get()).Auto=auto==true; return true end
function Pressurization:SetOutflow(value) value=tonumber(value); if not finite(value) then return false,"invalid_outflow" end; local p=ensure(self.state:Get()); p.ManualCommand=clamp(value,0,1); if not p.Auto then p.OutflowValve=p.ManualCommand end; return true end
function Pressurization:SetLandingAltitude(value) value=tonumber(value); if not finite(value) then return false,"invalid_landing_altitude" end; ensure(self.state:Get()).LandingAltitudeFt=clamp(value,-2000,12000); return true end
function Pressurization:Step(dt)
 local x=self.state:Get(); local p=ensure(x); dt=math.max(0,tonumber(dt) or 0); local bleed=x.BleedAir or {}; local aircraftAlt=math.max(0,tonumber(x.Altitude) or 0); local failure=x.Failures and x.Failures.Pressurization or {}; local valveFailed=failure.OutflowValve==true
 p.Pack1Available=bleed.Pack1Available==true; p.Pack2Available=bleed.Pack2Available==true; p.BleedSource1=bleed.Engine1Source==true or bleed.APUSource==true; p.BleedSource2=bleed.Engine2Source==true or bleed.APUSource==true; p.SourceAvailable=bleed.SourceAvailable==true or p.Pack1Available or p.Pack2Available
 local targetCabin=math.min(aircraftAlt,8000)
 if p.LandingAltitudeFt>0 and aircraftAlt<10000 then targetCabin=math.min(targetCabin,math.max(0,p.LandingAltitudeFt+500)) end
 if p.Dump then targetCabin=aircraftAlt end
 local desiredValve=p.Auto and clamp(0.25+(targetCabin/8000)*0.35+(p.SourceAvailable and 0 or 0.35),0,1) or p.ManualCommand
 if not p.SourceAvailable then desiredValve=1 end
 -- A failed outflow valve is stuck at its current position; it cannot be commanded by the controller.
 if valveFailed then desiredValve=p.OutflowValve end
 p.OutflowValve=p.OutflowValve+(desiredValve-p.OutflowValve)*clamp(dt*0.8,0,1)
 local leakRate=35+95*p.OutflowValve; local sourceRate=p.SourceAvailable and (55+35*clamp(tonumber(bleed.TotalAirflow) or 0,0,2)/2) or 0
 local rate=clamp((targetCabin-p.CabinAltitudeFt)*0.015+leakRate-sourceRate,-1500,1500)
 if not p.SourceAvailable then rate=math.max(rate,120) end
 p.CabinAltitudeRateFpm=rate; p.CabinAltitudeFt=clamp(p.CabinAltitudeFt+rate*dt/60,0,aircraftAlt+500)
 p.DifferentialPsi=clamp((aircraftAlt-p.CabinAltitudeFt)*0.00038,0,9.5); p.CabinAltitudeWarning=p.CabinAltitudeFt>=10000; p.DifferentialWarning=p.DifferentialPsi>=8.5; p.ReliefActive=p.DifferentialPsi>=8.6
 if p.ReliefActive then p.OutflowValve=math.max(p.OutflowValve,0.9) end
 p.Warning=p.CabinAltitudeWarning or p.DifferentialWarning or (not p.SourceAvailable and aircraftAlt>5000) or valveFailed
 x.Pressurization=p
end
return Pressurization
