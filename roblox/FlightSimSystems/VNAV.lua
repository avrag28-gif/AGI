-- FlightSim VNAV vertical guidance v0.2
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function VNAV.new(state) return setmetatable({state=state},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}
 x.VNAV=x.VNAV or {Mode="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0}
 local v=x.VNAV
 if nav.Mode~="VNAV" then v.Mode="OFF"; v.VerticalSpeed=0; v.PathError=0; return end
 v.Mode="VNAV"
 local wp=route[nav.ActiveWaypoint]
 local target=wp and tonumber(wp.Altitude) or tonumber(x.Autopilot.TargetAltitude)
 if not target then v.TargetAltitude=nil; v.VerticalSpeed=0; return end
 v.TargetAltitude=clamp(target,0,60000)
 v.PathError=v.TargetAltitude-(tonumber(x.Altitude) or 0)
 local distance=math.max(1,tonumber(nav.DistanceToWaypoint) or 1)
 local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60)
 local fps=speed*1.68781
 local desiredVS=clamp(v.PathError*0.12,-2500,2500)
 if distance<10000 then desiredVS=clamp(v.PathError*0.20,-1800,1800) end
 if math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 v.VerticalSpeed=desiredVS
 v.DescentPathAngle=math.deg(math.atan2(desiredVS/60,fps))
 nav.CommandAltitude=v.TargetAltitude
 nav.CommandVerticalSpeed=desiredVS
end
return VNAV
