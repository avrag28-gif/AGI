-- FlightSim Hydraulic System v0.1
-- Modular hydraulic pressure/availability model.
-- This is a simulation model, not certified aircraft software.

local Hydraulic = {}
Hydraulic.__index = Hydraulic

local DEFAULTS = {
	MaxPressure = 3000,
	MinOperationalPressure = 1800,
	AccumulatorPressure = 1000,
	PumpBuildRate = 900,
	LeakRate = 0,
	ReservoirCapacity = 1,
}

function Hydraulic.new()
	return setmetatable({
		state = {
			A = {Pressure = 0, Reservoir = 1, PumpOn = false, Available = false},
			B = {Pressure = 0, Reservoir = 1, PumpOn = false, Available = false},
			MaxPressure = DEFAULTS.MaxPressure,
		},
	}, Hydraulic)
end

function Hydraulic:GetState()
	return self.state
end

function Hydraulic:SetPump(system, enabled)
	if system ~= "A" and system ~= "B" then return false end
	self.state[system].PumpOn = enabled == true
	return true
end

function Hydraulic:SetLeakRate(system, rate)
	if system ~= "A" and system ~= "B" then return false end
	self.state[system].LeakRate = math.max(0, tonumber(rate) or 0)
	return true
end

function Hydraulic:Consume(system, amount)
	if system ~= "A" and system ~= "B" then return false end
	local s = self.state[system]
	s.Reservoir = math.max(0, s.Reservoir - math.max(0, tonumber(amount) or 0))
	return true
end

function Hydraulic:Step(dt)
	assert(type(dt) == "number" and dt >= 0, "Hydraulic:Step requires a non-negative dt")

	for _, name in ipairs({"A", "B"}) do
		local s = self.state[name]
		local leak = s.LeakRate or DEFAULTS.LeakRate

		if s.Reservoir <= 0 then
			s.PumpOn = false
			s.Pressure = math.max(0, s.Pressure - DEFAULTS.PumpBuildRate * dt)
		else
			if s.PumpOn then
				s.Pressure = math.min(DEFAULTS.MaxPressure, s.Pressure + DEFAULTS.PumpBuildRate * dt)
			else
				s.Pressure = math.max(0, s.Pressure - DEFAULTS.PumpBuildRate * 0.35 * dt)
			end
		end

		if leak > 0 then
			s.Pressure = math.max(0, s.Pressure - leak * dt)
		end

		s.Available = s.Pressure >= DEFAULTS.MinOperationalPressure
	end

	return self.state
end

return Hydraulic
