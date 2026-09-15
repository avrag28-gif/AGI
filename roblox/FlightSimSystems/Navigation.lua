-- FlightSim navigation / LNAV foundation v0.3
local Navigation = {}
Navigation.__index = Navigation
local function wrap360(v) return (v % 360 + 360) % 360 end
local function headingError(t,c) return (t-c+540)%360-180 end
local function distance2D(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap360(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
local function crossTrack(a,b,p) local x,z=b.X-a.X,b.Z-a.Z; local px,pz=p.X-a.X,p.Z-a.Z; local l=math.sqrt(x*x+z*z); if l<.001 then return 0 end; return (x*pz-z*px)/l end
function Navigation.new(state) return setmetatable({state=state},Navigation) end
function Navigation:Step(dt)
	local x=self.state:Get(); local nav=x.Navigation; if not nav then return end
	local route=nav.Route or {}; local i=math.max(1,math.floor(nav.ActiveWaypoint or 1)); local wp=route[i]
	if wp and typeof(wp.Position)=="Vector3" then
		nav.DistanceToWaypoint=distance2D(x.Position,wp.Position); nav.BearingToWaypoint=bearing(x.Position,wp.Position)
		local prev=route[i-1]
		nav.CrossTrackError=(prev and typeof(prev.Position)=="Vector3") and crossTrack(prev.Position,wp.Position,x.Position) or 0
		local capture=math.clamp(tonumber(wp.CaptureRadius) or 2500,250,10000)
		if nav.DistanceToWaypoint<=capture and i<#route then nav.ActiveWaypoint=i+1; wp=route[nav.ActiveWaypoint]; nav.DistanceToWaypoint=distance2D(x.Position,wp.Position); nav.BearingToWaypoint=bearing(x.Position,wp.Position) end
		if nav.Mode=="LNAV" then
			local intercept=math.clamp(-nav.CrossTrackError*0.02,-30,30)
			nav.CommandHeading=wrap360(nav.BearingToWaypoint+intercept)
		else nav.CommandHeading=wrap360(x.Autopilot.TargetHeading or x.Heading) end
	else
		nav.CommandHeading=wrap360(x.Autopilot.TargetHeading or x.Heading); if #route>0 then nav.RouteComplete=true end
	end
	nav.HeadingError=headingError(nav.CommandHeading,x.Heading)
	nav.CommandAltitude=x.Autopilot.TargetAltitude or x.Altitude
	return nav
end
function Navigation:SetRoute(route) local x=self.state:Get(); x.Navigation.Route=route or {}; x.Navigation.ActiveWaypoint=1; x.Navigation.RouteComplete=false end
return Navigation
