-- FlightSim brake system v0.2
local Brakes = {}
Brakes.__index = Brakes

function Brakes.new(state)
	return setmetatable({state = state}, Brakes)
end

function Brakes:Step(dt)
	local x = self.state:Get()
	local brakes = x.Brakes
	brakes.BrakePressure = tonumber(brakes.BrakePressure) or 0

	local target = brakes.Parking and 1 or 0
	local hydraulic = math.max(x.Hydraulic.A or 0, x.Hydraulic.B or 0)
	local available = math.clamp(hydraulic / 1800, 0, 1)
	target *= available

	brakes.BrakePressure += (target - brakes.BrakePressure) * math.min(1, 6 * dt)
	brakes.BrakePressure = math.clamp(brakes.BrakePressure, 0, 1)
end

return Brakes
