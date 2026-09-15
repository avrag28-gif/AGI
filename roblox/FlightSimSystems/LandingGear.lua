-- FlightSim landing gear system v0.1
local LandingGear = {}
LandingGear.__index = LandingGear

function LandingGear.new(state)
	return setmetatable({state = state}, LandingGear)
end

function LandingGear:Step(dt)
	local x = self.state:Get()
	local gear = x.Gear
	local hydraulic = math.max(x.Hydraulic.A or 0, x.Hydraulic.B or 0)
	local powered = hydraulic >= 1000

	x.GearPosition = x.GearPosition or {Nose = gear.Nose and 1 or 0, Left = gear.Left and 1 or 0, Right = gear.Right and 1 or 0}
	if powered then
		local target = gear.Nose and 1 or 0
		x.GearPosition.Nose += (target - x.GearPosition.Nose) * math.min(1, 2 * dt)
		target = gear.Left and 1 or 0
		x.GearPosition.Left += (target - x.GearPosition.Left) * math.min(1, 2 * dt)
		target = gear.Right and 1 or 0
		x.GearPosition.Right += (target - x.GearPosition.Right) * math.min(1, 2 * dt)
	end
end

return LandingGear
