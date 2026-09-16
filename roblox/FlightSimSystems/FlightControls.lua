-- FlightSim flight-control system v0.4
-- Server-authoritative control-surface scheduling and airspeed-dependent authority.
-- Values are simulation approximations, not certified aircraft data.
local FlightControls={}; FlightControls.__index=FlightControls
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
function FlightControls.new(state) return setmetatable({state=state},FlightControls) end
function FlightControls:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local ap=x.Autopilot or {}
 local speed=math.max(tonumber(x.Airspeed) or 0,0)
 local hydraulic=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0,1)
 local dynamicAuthority=clamp(0.22+speed/105,0.22,1.15)
 local authority=clamp(hydraulic*dynamicAuthority,0,1)
 local ground=x.GroundContact==true
 x.Surface=x.Surface or {Aileron=0,Elevator=0,Rudder=0,Flap=0}
 local ail=clamp(tonumber(c.Aileron) or 0,-1,1)
 local ele=clamp(tonumber(c.Elevator) or 0,-1,1)
 if ap.Enabled then
  ail=clamp(tonumber(ap.CommandAileron) or ail,-1,1)
  ele=clamp(tonumber(ap.CommandElevator) or ele,-1,1)
 end
 local trimEffect=clamp((x.TrimPitch or 0)/10,-0.45,0.45)
 ele=clamp(ele+trimEffect,-1,1)
 -- Reduce lateral control authority while stationary; preserve enough rudder for steering blend.
 local groundAileron=ground and clamp(speed/45,0,1) or 1
 local groundElevator=ground and clamp((speed-35)/45,0.12,1) or 1
 local groundRudder=ground and clamp((speed-8)/28,0,1) or 1
 local ailTarget=ail*authority*groundAileron
 local eleTarget=ele*authority*groundElevator
 local rudTarget=clamp(c.Rudder or 0,-1,1)*authority*groundRudder
 x.Surface.Aileron=approach(x.Surface.Aileron,ailTarget,9,dt)
 x.Surface.Elevator=approach(x.Surface.Elevator,eleTarget,7,dt)
 x.Surface.Rudder=approach(x.Surface.Rudder,rudTarget,6,dt)
 local flapTarget=clamp(c.Flap or 0,0,1)
 x.Surface.Flap=approach(x.Surface.Flap,flapTarget,2,dt)
 x.ControlFeel=x.ControlFeel or {}
 x.ControlFeel.HydraulicAuthority=hydraulic
 x.ControlFeel.DynamicAuthority=dynamicAuthority
 x.ControlFeel.AileronAuthority=groundAileron
 x.ControlFeel.ElevatorAuthority=groundElevator
 x.ControlFeel.RudderAuthority=groundRudder
end
return FlightControls
