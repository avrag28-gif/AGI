-- FlightSim flight-control system v1.6
-- Server-authoritative control-surface scheduling and hydraulic demand reporting.
-- Hydraulic authority is separated by control group so standby pressure cannot
-- incorrectly restore every primary flight-control surface.
--
-- Important modeling rule: hydraulic pressure limits available surface travel;
-- airspeed/dynamic pressure limits the aerodynamic moment in Physics.lua. Do
-- not apply the same low-speed penalty to both layers or control response is
-- double-attenuated.
local FlightControls={}; FlightControls.__index=FlightControls
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
local function pressure(system) return type(system)=="table" and math.max(tonumber(system.Pressure) or 0,0) or math.max(tonumber(system) or 0,0) end
function FlightControls.new(state) return setmetatable({state=state},FlightControls) end
function FlightControls:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local ap=x.Autopilot or {}; local failures=x.FailureEffects or {}; local h=x.Hydraulic or {}
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local pA=pressure(h.A); local pB=pressure(h.B); local pS=pressure(h.Standby)
 local aHyd=clamp(pA/1800,0,1); local bHyd=clamp(pB/1800,0,1); local sHyd=clamp(pS/1800,0,1)
 -- Dynamic pressure is modeled in Physics. Keep this factor for telemetry only;
 -- applying it to surface travel here would double-attenuate low-speed control.
 local dynamicAuthority=clamp(0.22+speed/105,0.22,1.15); local ground=x.GroundContact==true
 x.Surface=x.Surface or {Aileron=0,Elevator=0,Rudder=0,Flap=0,Speedbrake=0,SpoilerLeft=0,SpoilerRight=0}
 local ail=clamp(tonumber(c.Aileron) or 0,-1,1); local ele=clamp(tonumber(c.Elevator) or 0,-1,1)
 if ap.Enabled then ail=clamp(tonumber(ap.CommandAileron) or ail,-1,1); ele=clamp(tonumber(ap.CommandElevator) or ele,-1,1) end
 ele=clamp(ele+clamp((x.TrimPitch or 0)/10,-0.45,0.45),-1,1)
 local groundAileron=ground and clamp(speed/45,0,1) or 1; local groundElevator=ground and clamp((speed-35)/45,0.12,1) or 1; local groundRudder=ground and clamp((speed-8)/28,0,1) or 1
 local ailFailure=clamp(failures.AileronAuthority or 1,0,1); local eleFailure=clamp(failures.ElevatorAuthority or 1,0,1); local rudFailure=clamp(failures.RudderAuthority or 1,0,1)
 -- Primary flight-control hydraulic authority is pressure-only in flight.
 -- Standby is intentionally restricted to rudder authority in this simulation
 -- contract; it must not become a universal substitute for failed primaries.
 local ailHyd=math.max(aHyd,bHyd); local eleHyd=math.max(aHyd,bHyd); local rudHyd=math.max(aHyd,bHyd,sHyd*0.85)
 -- Explicit simulation approximation for residual/manual control when both
 -- primary hydraulic systems are unavailable. This is not an AFM/FCOM model.
 local manualReversion=(math.max(aHyd,bHyd)<0.05) and 0.12 or 0
 ailHyd=math.max(ailHyd,manualReversion); eleHyd=math.max(eleHyd,manualReversion)
 local rudderCommand=clamp(tonumber(c.Rudder) or 0,-1,1)
 -- Yaw-damper input is an independent rudder command, not pilot pedal feedback.
 -- Keep it out of ground steering: the ground directional-control path owns
 -- rudder input while on the runway/taxiway. The FAA describes the yaw damper
 -- as an independent input to the rudder PCU, separate from pilot pedals.
 local yawDamper=(c.YawDamper==true) or (ap.YawDamper==true)
 local yawDamperEngaged=yawDamper and not ground
 if yawDamperEngaged then
  local beta=clamp(tonumber(x.Sideslip or x.Beta) or 0,-12,12)
  local yawRate=clamp(tonumber(x.YawRate) or 0,-10,10)
  rudderCommand=clamp(rudderCommand-beta*0.08-yawRate*0.025,-1,1)
 end
 local ailTarget=ail*ailHyd*groundAileron*ailFailure; local eleTarget=ele*eleHyd*groundElevator*eleFailure; local rudTarget=rudderCommand*rudHyd*groundRudder*rudFailure
 local flapTarget=(x.FlapSystem and tonumber(x.FlapSystem.Target) or nil); flapTarget=clamp((flapTarget~=nil and flapTarget/40 or tonumber(c.Flap) or 0),0,1)
 x.Surface.Aileron=approach(x.Surface.Aileron,ailTarget,9,dt); x.Surface.Elevator=approach(x.Surface.Elevator,eleTarget,7,dt); x.Surface.Rudder=approach(x.Surface.Rudder,rudTarget,6,dt); x.Surface.Flap=approach(x.Surface.Flap,flapTarget,2,dt)
 x.ControlFeel=x.ControlFeel or {}
 -- These are the actual normalized control-group authorities consumed by
 -- Autopilot. Surface travel and AP authority share the same hydraulic gate.
 x.ControlFeel.HydraulicAuthority=math.max(ailHyd,eleHyd,rudHyd); x.ControlFeel.DynamicAuthority=dynamicAuthority
 x.ControlFeel.AileronAuthority=clamp(ailHyd*groundAileron*ailFailure,0,1)
 x.ControlFeel.ElevatorAuthority=clamp(eleHyd*groundElevator*eleFailure,0,1)
 x.ControlFeel.RudderAuthority=clamp(rudHyd*groundRudder*rudFailure,0,1)
 x.ControlFeel.HydraulicA=aHyd; x.ControlFeel.HydraulicB=bHyd; x.ControlFeel.HydraulicStandby=sHyd; x.ControlFeel.ManualReversion=manualReversion>0; x.ControlFeel.YawDamperActive=yawDamperEngaged
 x.FlightControls=x.FlightControls or {}
 x.FlightControls.PrimaryHydraulicA=aHyd>0.28
 x.FlightControls.PrimaryHydraulicB=bHyd>0.28
 x.FlightControls.ManualReversion=manualReversion>0
 x.FlightControls.FeelDifferential=clamp((aHyd-bHyd)*dynamicAuthority,-1,1)
 x.FlightControls.ElevatorPCU1=eleHyd>0.05
 x.FlightControls.ElevatorPCU2=eleHyd>0.05
 x.FlightControls.RudderPCU=rudHyd>0.05
 x.FlightControls.AileronPCU=ailHyd>0.05
 x.FlightControls.YawDamper=yawDamperEngaged
 -- Demand is the requested actuator load and remains pressure-independent.
 local ailLoad=math.abs(ail)*groundAileron*ailFailure; local eleLoad=math.abs(ele)*groundElevator*eleFailure; local rudLoad=math.abs(rudderCommand)*groundRudder*rudFailure
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.FlightControls=clamp(math.max(ailLoad,eleLoad,rudLoad),0,1); x.HydraulicDemand.FlightControlsA=clamp(math.max(eleLoad,rudLoad*0.7),0,1); x.HydraulicDemand.FlightControlsB=clamp(math.max(ailLoad,eleLoad*0.7),0,1)
 return true
end
return FlightControls
