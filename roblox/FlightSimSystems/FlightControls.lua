-- FlightSim flight-control system v0.8
-- Server-authoritative control-surface scheduling, failure-aware authority and hydraulic demand reporting.
-- Values are simulation approximations, not certified aircraft data.
local FlightControls={}; FlightControls.__index=FlightControls
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
function FlightControls.new(state) return setmetatable({state=state},FlightControls) end
function FlightControls:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local ap=x.Autopilot or {}; local failures=x.FailureEffects or {}
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local hydraulic=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0,1)
 local dynamicAuthority=clamp(0.22+speed/105,0.22,1.15); local authority=clamp(hydraulic*dynamicAuthority,0,1); local ground=x.GroundContact==true
 x.Surface=x.Surface or {Aileron=0,Elevator=0,Rudder=0,Flap=0}
 local ail=clamp(tonumber(c.Aileron) or 0,-1,1); local ele=clamp(tonumber(c.Elevator) or 0,-1,1)
 if ap.Enabled then ail=clamp(tonumber(ap.CommandAileron) or ail,-1,1); ele=clamp(tonumber(ap.CommandElevator) or ele,-1,1) end
 ele=clamp(ele+clamp((x.TrimPitch or 0)/10,-0.45,0.45),-1,1)
 local groundAileron=ground and clamp(speed/45,0,1) or 1; local groundElevator=ground and clamp((speed-35)/45,0.12,1) or 1; local groundRudder=ground and clamp((speed-8)/28,0,1) or 1
 local ailTarget=ail*authority*groundAileron*clamp(failures.AileronAuthority or 1,0,1); local eleTarget=ele*authority*groundElevator*clamp(failures.ElevatorAuthority or 1,0,1); local rudTarget=clamp(c.Rudder or 0,-1,1)*authority*groundRudder*clamp(failures.RudderAuthority or 1,0,1)
 local flapTarget=(x.FlapSystem and tonumber(x.FlapSystem.Target) or nil); flapTarget=clamp((flapTarget~=nil and flapTarget/40 or tonumber(c.Flap) or 0),0,1)
 x.Surface.Aileron=approach(x.Surface.Aileron,ailTarget,9,dt); x.Surface.Elevator=approach(x.Surface.Elevator,eleTarget,7,dt); x.Surface.Rudder=approach(x.Surface.Rudder,rudTarget,6,dt); x.Surface.Flap=approach(x.Surface.Flap,flapTarget,2,dt)
 x.ControlFeel=x.ControlFeel or {}; x.ControlFeel.HydraulicAuthority=hydraulic; x.ControlFeel.DynamicAuthority=dynamicAuthority
 x.ControlFeel.AileronAuthority=groundAileron*clamp(failures.AileronAuthority or 1,0,1); x.ControlFeel.ElevatorAuthority=groundElevator*clamp(failures.ElevatorAuthority or 1,0,1); x.ControlFeel.RudderAuthority=groundRudder*clamp(failures.RudderAuthority or 1,0,1)
 local ailLoad=math.abs(ailTarget); local eleLoad=math.abs(eleTarget); local rudLoad=math.abs(rudTarget)
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.FlightControls=clamp(math.max(ailLoad,eleLoad,rudLoad),0,1)
 x.HydraulicDemand.A=clamp(math.max(eleLoad,rudLoad*0.7),0,1)
 x.HydraulicDemand.B=clamp(math.max(ailLoad,eleLoad*0.7),0,1)
 return true
end
return FlightControls
