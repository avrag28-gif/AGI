-- FlightSim navigation / LNAV / VOR guidance v0.6
-- Simulation approximation; procedure coding and certified nav databases are outside this layer.
local Navigation={}; Navigation.__index=Navigation
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap360(v) return (v%360+360)%360 end
local function headingError(t,c) return (t-c+540)%360-180 end
local function distance2D(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap360(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
local function crossTrack(a,b,p) local x,z=b.X-a.X,b.Z-a.Z; local px,pz=p.X-a.X,p.Z-a.Z; local l=math.sqrt(x*x+z*z); if l<.001 then return 0 end; return (x*pz-z*px)/l end
local function segmentCourse(a,b) return bearing(a,b) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function Navigation.new(state) return setmetatable({state=state},Navigation) end
function Navigation:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation; if not nav then return end
 nav.CommandHeading=nil; nav.CommandAltitude=nil; nav.CommandVerticalSpeed=nil; nav.RouteComplete=false
 local route=nav.Route or {}; local i=math.max(1,math.floor(nav.ActiveWaypoint or 1)); local wp=route[i]
 if wp and typeof(wp.Position)=="Vector3" then
  local prev=route[i-1]; local pos=x.Position
  nav.DistanceToWaypoint=distance2D(pos,wp.Position); nav.BearingToWaypoint=bearing(pos,wp.Position)
  nav.CrossTrackError=(prev and typeof(prev.Position)=="Vector3") and crossTrack(prev.Position,wp.Position,pos) or 0
  local capture=clamp(tonumber(wp.CaptureRadius) or 2500,250,10000); local nextWp=route[i+1]
  if nav.DistanceToWaypoint<=capture and i<#route then
   nav.ActiveWaypoint=i+1; wp=route[nav.ActiveWaypoint]; nav.DistanceToWaypoint=distance2D(pos,wp.Position); nav.BearingToWaypoint=bearing(pos,wp.Position); prev=route[nav.ActiveWaypoint-1]; nav.CrossTrackError=(prev and typeof(prev.Position)=="Vector3") and crossTrack(prev.Position,wp.Position,pos) or 0
  elseif nav.DistanceToWaypoint<=capture and i==#route then nav.RouteComplete=true end
  local desired=nav.BearingToWaypoint
  if nav.Mode=="LNAV" then
   local pathCourse=(prev and typeof(prev.Position)=="Vector3") and segmentCourse(prev.Position,wp.Position) or desired; local xte=tonumber(nav.CrossTrackError) or 0; local intercept=clamp(-xte*0.02,-30,30); if nav.DistanceToWaypoint<capture then intercept=intercept*(nav.DistanceToWaypoint/capture) end; desired=wrap360(pathCourse+intercept)
  elseif nav.Mode=="VOR" then
   local vor=nav.VOR; if vor and vor.Available and nav.NAV1Receiver=="VOR" then desired=wrap360(vor.Course-clamp(tonumber(vor.CourseError) or 0,-30,30)*0.8) else desired=wrap360(x.Autopilot.TargetHeading or x.Heading) end
  elseif nav.Mode=="HDG" or nav.Mode=="APP" then desired=wrap360(x.Autopilot.TargetHeading or x.Heading) end
  nav.CommandHeading=desired
 else
  nav.CommandHeading=wrap360(x.Autopilot.TargetHeading or x.Heading); nav.RouteComplete=#route>0; nav.DistanceToWaypoint=0; nav.BearingToWaypoint=nav.CommandHeading; nav.CrossTrackError=0
 end
 nav.HeadingError=headingError(nav.CommandHeading,x.Heading)
 -- Altitude is only a computed navigation output when an active vertical mode owns it.
 if nav.Mode=="HDG" or nav.Mode=="LNAV" or nav.Mode=="VOR" or nav.Mode=="APP" then nav.CommandAltitude=nil end
 return nav
end
function Navigation:SetRoute(route) local x=self.state:Get(); x.Navigation.Route=route or {}; x.Navigation.ActiveWaypoint=1; x.Navigation.RouteComplete=false end
return Navigation
