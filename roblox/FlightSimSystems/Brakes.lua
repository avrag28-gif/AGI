-- FlightSim brake system v0.1
local Brakes = {}
Brakes.__index = Brakes

function Brakes.new(state)
	return setmetatable({state = state}, Brakes)
end

function Brakes:Step(dt)
	local x = self.state:Get()
	x.BrakePressure = x.BrakePressure or 0
	local target = x.Brakes.Parking and 1 or 0
	local hydraulic = math.max(x.Hydraulic.A or 0, x.Hydraulic.B or 0)
	local available = math.clamp(hydraulic / 1800, 0, 1)
	target *= available
	x.BrakePressure += (target - x.BrakePressure) * math.min(1, 6 * dt)
end

return Brakes
