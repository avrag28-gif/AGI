-- FlightSim flight-control system v0.1
local FlightControls = {}
FlightControls.__index = FlightControls

function FlightControls.new(state)
	return setmetatable({state = state}, FlightControls)
end

function FlightControls:Step(dt)
	local x = self.state:Get()
	local c = x.Controls
	local hydraulic = math.max(x.Hydraulic.A or 0, x.Hydraulic.B or 0)
	local authority = math.clamp(hydraulic / 1800, 0, 1)

	-- Server-side actuator response. Inputs are commands; surfaces move through
	-- the system model rather than teleporting directly to a visual pose.
	x.Surface = x.Surface or {Aileron = 0, Elevator = 0, Rudder = 0, Flap = 0}
	x.Surface.Aileron += (math.clamp(c.Aileron, -1, 1) * authority - x.Surface.Aileron) * math.min(1, 8 * dt)
	x.Surface.Elevator += (math.clamp(c.Elevator, -1, 1) * authority - x.Surface.Elevator) * math.min(1, 8 * dt)
	x.Surface.Rudder += (math.clamp(c.Rudder, -1, 1) * authority - x.Surface.Rudder) * math.min(1, 6 * dt)
	x.Surface.Flap += (math.clamp(c.Flap, 0, 1) - x.Surface.Flap) * math.min(1, 2 * dt)
end

return FlightControls
