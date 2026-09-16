-- FlightSim VNAV vertical guidance v0.3
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function VNAV.new(state) return setmetatable({state=state},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}
 x.VNAV=x.VNAV or {Mode="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=0}
 local v=x.VNAV
 if nav.Mode~="VNAV" then v.Mode="OFF"; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=0; return true end
 v.Mode="VNAV"
 local wp=route[nav.ActiveWaypoint]
 local target=wp and tonumber(wp.Altitude) or tonumber(x.Autopilot and x.Autopilot.TargetAltitude)
 if not finite(target) then v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=0; return true end
 v.TargetAltitude=clamp(target,0,60000)
 local altitude=finite(x.Altitude) and x.Altitude or 0
 v.PathError=v.TargetAltitude-altitude
 local distance=math.max(1,tonumber(nav.DistanceToWaypoint) or 1)
 local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60)
 -- Build a geometric path to the active waypoint rather than deriving VS only
 -- from altitude error. Distance and altitude use the simulation's world units.
 local pathAngle=math.atan2(v.PathError,distance)
 local maxAngle=math.rad(6)
 pathAngle=clamp(pathAngle,-maxAngle,maxAngle)
 local fps=speed*1.68781
 local desiredVS=math.tan(pathAngle)*fps*60
 -- Reduce command near capture so the aircraft settles instead of chasing the
 -- waypoint with a large last-second vertical correction.
 if distance<1000 then desiredVS=clamp(desiredVS,-800,800)
 elseif distance<5000 then desiredVS=clamp(desiredVS,-1800,1800)
 else desiredVS=clamp(desiredVS,-2500,2500) end
 if math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 v.VerticalSpeed=desiredVS
 v.CommandVerticalSpeed=desiredVS
 v.DescentPathAngle=math.deg(pathAngle)
 nav.CommandAltitude=v.TargetAltitude
 nav.CommandVerticalSpeed=desiredVS
 return true
end
return VNAV
