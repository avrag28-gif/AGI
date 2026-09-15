-- FlightSim VNAV foundation v0.1
local VNAV = {}
VNAV.__index = VNAV

function VNAV.new(state)
	return setmetatable({state=state}, VNAV)
end

function VNAV:Step(dt)
	local x=self.state:Get()
	local nav=x.Navigation
	x.VNAV=x.VNAV or {Mode="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0}
	local v=x.VNAV
	if nav.Mode ~= "VNAV" then
		v.Mode="OFF"
		return
	end

	v.Mode="VNAV"
	local wp=(nav.Route or {})[nav.ActiveWaypoint]
	if wp and tonumber(wp.Altitude) then
		v.TargetAltitude=wp.Altitude
	else
		v.TargetAltitude=x.Autopilot.TargetAltitude
	end

	if v.TargetAltitude then
		v.PathError=v.TargetAltitude-x.Altitude
		v.VerticalSpeed=math.clamp(v.PathError*0.08,-2500,2500)
		x.Navigation.CommandAltitude=v.TargetAltitude
	end
end

return VNAV
