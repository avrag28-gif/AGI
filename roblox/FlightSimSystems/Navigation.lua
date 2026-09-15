-- FlightSim navigation / LNAV foundation v0.2
local Navigation = {}
Navigation.__index = Navigation

local function wrap360(v)
	v = v % 360
	if v < 0 then v += 360 end
	return v
end

local function headingError(target, current)
	return (target - current + 540) % 360 - 180
end

local function distance2D(a,b)
	local dx,dz=b.X-a.X,b.Z-a.Z
	return math.sqrt(dx*dx+dz*dz)
end

local function bearing(a,b)
	return wrap360(math.deg(math.atan2(b.X-a.X,b.Z-a.Z)))
end

local function crossTrack(a,b,p)
	local abx,abz=b.X-a.X,b.Z-a.Z
	local apx,apz=p.X-a.X,p.Z-a.Z
	local len=math.sqrt(abx*abx+abz*abz)
	if len < 0.001 then return 0 end
	return (abx*apz-abz*apx)/len
end

function Navigation.new(state)
	return setmetatable({state=state},Navigation)
end

function Navigation:Step(dt)
	local x=self.state:Get()
	x.Navigation=x.Navigation or {Mode="HDG",ActiveWaypoint=1,Route={},DistanceToWaypoint=0,BearingToWaypoint=x.Heading,CrossTrackError=0}
	local nav=x.Navigation
	local route=nav.Route or {}
	local i=nav.ActiveWaypoint or 1
	local wp=route[i]
	local target= x.Autopilot.TargetHeading or x.Heading

	if wp and typeof(wp.Position)=="Vector3" then
		nav.DistanceToWaypoint=distance2D(x.Position,wp.Position)
		nav.BearingToWaypoint=bearing(x.Position,wp.Position)
		local previous=route[i-1]
		if nav.Mode=="LNAV" then target=nav.BearingToWaypoint end
		if previous and typeof(previous.Position)=="Vector3" then
			nav.CrossTrackError=crossTrack(previous.Position,wp.Position,x.Position)
		else
			nav.CrossTrackError=0
		end
	elseif nav.Mode=="LNAV" then
		nav.RouteComplete=#route>0
	end

	nav.CommandHeading=wrap360(target)
	nav.HeadingError=headingError(nav.CommandHeading,x.Heading)
	nav.CommandAltitude=x.Autopilot.TargetAltitude or x.Altitude
	return nav
end

function Navigation:SetRoute(route)
	local x=self.state:Get()
	x.Navigation=x.Navigation or {Mode="HDG",ActiveWaypoint=1,Route={}}
	x.Navigation.Route=route or {}
	x.Navigation.ActiveWaypoint=1
	x.Navigation.RouteComplete=false
end

return Navigation
