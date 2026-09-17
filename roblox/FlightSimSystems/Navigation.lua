-- FlightSim navigation / LNAV / VOR / ILS guidance v1.4
-- Simulation approximation; procedure coding and certified nav databases are outside this layer.
local Navigation={}; Navigation.__index=Navigation
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function wrap360(v) return (v%360+360)%360 end
local function headingError(t,c) return (t-c+540)%360-180 end
local function distance2D(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap360(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
local function crossTrack(a,b,p) local x,z=b.X-a.X,b.Z-a.Z; local px,pz=p.X-a.X,p.Z-a.Z; local l=math.sqrt(x*x+z*z); if l<.001 then return 0 end; return (x*pz-z*px)/l end
local function segmentCourse(a,b) return bearing(a,b) end
local function velocityTrack(v)
 local dx,dz=v.X,v.Z
 if dx*dx+dz*dz<1 then return nil end
 return wrap360(math.deg(math.atan2(dx,dz)))
end
local function groundSpeed(v)
 local horizontalSquared=v.X*v.X+v.Z*v.Z
 return math.sqrt(math.max(horizontalSquared,0))/0.514444
end
function Navigation.new(state) return setmetatable({state=state},Navigation) end
function Navigation:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation; if not nav then return end
 nav.CommandHeading=nil; nav.CommandAltitude=nil; nav.CommandVerticalSpeed=nil
 local route=nav.Route or {}; local i=math.max(1,math.floor(tonumber(nav.ActiveWaypoint) or 1)); local wp=route[i]
 local pos=typeof(x.Position)=="Vector3" and x.Position or Vector3.zero
 local velocity=typeof(x.Velocity)=="Vector3" and x.Velocity or Vector3.zero
 local track=velocityTrack(velocity)
 nav.GroundTrack=track
 nav.GroundSpeed=groundSpeed(velocity)
 local heading=finite(x.Heading) and wrap360(x.Heading) or 0
 if wp and typeof(wp.Position)=="Vector3" then
  local prev=route[i-1]; nav.DistanceToWaypoint=distance2D(pos,wp.Position); nav.BearingToWaypoint=bearing(pos,wp.Position)
  nav.CrossTrackError=(prev and typeof(prev.Position)=="Vector3") and crossTrack(prev.Position,wp.Position,pos) or 0
  local capture=clamp(tonumber(wp.CaptureRadius) or 2500,250,10000)
  if nav.DistanceToWaypoint<=capture and i<#route then
   nav.ActiveWaypoint=i+1; wp=route[nav.ActiveWaypoint]; nav.DistanceToWaypoint=distance2D(pos,wp.Position); nav.BearingToWaypoint=bearing(pos,wp.Position); prev=route[nav.ActiveWaypoint-1]; nav.CrossTrackError=(prev and typeof(prev.Position)=="Vector3") and crossTrack(prev.Position,wp.Position,pos) or 0
  elseif nav.DistanceToWaypoint<=capture and i==#route then
   nav.RouteComplete=true
  end
  local desired=nav.BearingToWaypoint
  if nav.Mode=="LNAV" then
   local pathCourse=(prev and typeof(prev.Position)=="Vector3") and segmentCourse(prev.Position,wp.Position) or desired
   local xte=tonumber(nav.CrossTrackError) or 0
   nav.PathCourse=pathCourse
   local lookAhead=clamp(nav.DistanceToWaypoint*0.35,750,5000)
   local intercept=math.deg(math.atan(xte/math.max(1,lookAhead)))
   intercept=clamp(intercept,-30,30)
   local referenceTrack=track or (finite(x.Heading) and wrap360(x.Heading) or pathCourse)
   local trackError=headingError(pathCourse,referenceTrack)
   local trackCorrection=clamp(trackError*0.65,-20,20)
   desired=wrap360(pathCourse+intercept+trackCorrection)
   nav.LNAVInterceptAngle=intercept
   nav.LNAVTrackError=trackError
  elseif nav.Mode=="VOR" then
   local vor=nav.NAV1Signal; if nav.NAV1Receiver=="VOR" and vor and vor.Available then desired=wrap360(vor.Course-clamp(tonumber(vor.CourseError) or 0,-30,30)*0.8) else desired=wrap360(x.Autopilot.TargetHeading or heading) end
  elseif nav.Mode=="APP" then
   local ils=nav.NAV1Signal
   if nav.NAV1Receiver=="ILS" and ils and ils.Available and ils.LocalizerValid then
    local intercept=clamp(tonumber(ils.Localizer) or 0,-1,1)*28; desired=wrap360((nav.ApproachRunway and nav.ApproachRunway.Heading or heading)+intercept)
    if ils.GlideSlopeValid and type(ils.DesiredAltitude)=="number" and ils.DesiredAltitude==ils.DesiredAltitude and ils.DesiredAltitude>-math.huge and ils.DesiredAltitude<math.huge then nav.CommandAltitude=ils.DesiredAltitude end
   else desired=wrap360(x.Autopilot.TargetHeading or heading) end
  elseif nav.Mode=="HDG" then desired=wrap360(x.Autopilot.TargetHeading or heading) end
  nav.CommandHeading=desired
 else
  nav.CommandHeading=wrap360(x.Autopilot.TargetHeading or heading); nav.DistanceToWaypoint=0; nav.BearingToWaypoint=nav.CommandHeading; nav.CrossTrackError=0; nav.PathCourse=nil; nav.LNAVInterceptAngle=0; nav.LNAVTrackError=0
  if #route==0 then nav.RouteComplete=true end
 end
 nav.HeadingError=headingError(nav.CommandHeading,heading)
 if nav.Mode=="HDG" or nav.Mode=="LNAV" or nav.Mode=="VOR" then nav.CommandAltitude=nil; nav.CommandVerticalSpeed=nil end
 return nav
end
function Navigation:SetRoute(route) local x=self.state:Get(); x.Navigation.Route=route or {}; x.Navigation.ActiveWaypoint=1; x.Navigation.RouteComplete=(#(route or {})==0) end
return Navigation
