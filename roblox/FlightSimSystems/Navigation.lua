-- FlightSim navigation foundation v0.1
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

function Navigation.new(state)
	return setmetatable({state = state}, Navigation)
end

function Navigation:Step(dt)
	local x = self.state:Get()
	x.Navigation = x.Navigation or {
		Mode = "HDG",
		ActiveWaypoint = 1,
		Route = {},
		DistanceToWaypoint = 0,
		BearingToWaypoint = x.Heading,
		CrossTrackError = 0,
		VerticalPath = nil,
	}

	local nav = x.Navigation
	local ap = x.Autopilot
	local target = ap.TargetHeading or x.Heading

	if nav.Mode == "LNAV" and nav.BearingToWaypoint then
		target = nav.BearingToWaypoint
	end

	nav.CommandHeading = wrap360(target)
	nav.HeadingError = headingError(nav.CommandHeading, x.Heading)
	nav.CommandAltitude = ap.TargetAltitude or x.Altitude
	return nav
end

function Navigation:SetRoute(route)
	local x = self.state:Get()
	x.Navigation = x.Navigation or {Mode = "HDG", ActiveWaypoint = 1, Route = {}}
	x.Navigation.Route = route or {}
	x.Navigation.ActiveWaypoint = 1
end

return Navigation
