-- FlightSim waypoint sequencing v0.1
local WaypointManager = {}
WaypointManager.__index = WaypointManager

local function distance(a,b)
	local dx, dz = a.X-b.X, a.Z-b.Z
	return math.sqrt(dx*dx + dz*dz)
end

local function bearing(a,b)
	local dx, dz = b.X-a.X, b.Z-a.Z
	return (math.deg(math.atan2(dx, dz)) + 360) % 360
end

function WaypointManager.new(state)
	return setmetatable({state=state}, WaypointManager)
end

function WaypointManager:Step(dt)
	local x=self.state:Get()
	local nav=x.Navigation
	local route=nav.Route or {}
	local i=nav.ActiveWaypoint or 1
	local wp=route[i]
	if not wp then
		nav.DistanceToWaypoint=0
		nav.BearingToWaypoint=x.Heading
		nav.RouteComplete=#route>0
		return
	end

	local pos=wp.Position
	if typeof(pos) ~= "Vector3" then
		nav.RouteError="invalid_waypoint_position"
		return
	end

	local d=distance(x.Position,pos)
	nav.DistanceToWaypoint=d
	nav.BearingToWaypoint=bearing(x.Position,pos)
	nav.RouteComplete=false

	local captureRadius=tonumber(wp.CaptureRadius) or 1500
	if d <= captureRadius then
		nav.ActiveWaypoint=i+1
		if nav.ActiveWaypoint > #route then
			nav.RouteComplete=true
		end
	end
end

return WaypointManager
