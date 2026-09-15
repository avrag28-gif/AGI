-- FlightSim Engine System v0.2
-- Modular turbofan start/run/shutdown state machine.
-- This is a simulation model, not certified aircraft software.

local Engine = {}
Engine.__index = Engine

local DEFAULTS = {
	StarterN2Rate = 18,
	StarterMaxN2 = 60,
	SpoolUpRate = 12,
	SpoolDownRate = 8,
	MinStartN2 = 20,
	LightOffN2 = 25,
	IdleN1 = 22,
	IdleN2 = 58,
	MaxN1 = 100,
	MaxN2 = 100,
	IdleEGT = 450,
	StartEGTPeak = 650,
	IdleOilPressure = 35,
	MaxOilPressure = 55,
	MaxFuelFlow = 100,
	MaxThrust = 1,
}

function Engine.new(index)
	assert(index == 1 or index == 2, "Engine index must be 1 or 2")
	return setmetatable({
		index = index,
		state = {
			N1 = 0,
			N2 = 0,
			EGT = 20,
			OilPressure = 0,
			FuelFlow = 0,
			Thrust = 0,
			Running = false,
			Starter = false,
			FuelOn = false,
			Ignition = false,
			GeneratorAvailable = false,
			StartFailed = false,
		},
	}, Engine)
end

function Engine:GetState()
	return self.state
end

function Engine:SetStarter(on)
	self.state.Starter = on == true
end

function Engine:SetFuel(on)
	self.state.FuelOn = on == true
end

function Engine:SetIgnition(on)
	self.state.Ignition = on == true
end

function Engine:SetThrottle(value)
	self.state.Throttle = math.clamp(tonumber(value) or 0, 0, 1)
end

function Engine:Shutdown()
	self.state.Running = false
	self.state.GeneratorAvailable = false
	self.state.FuelOn = false
	self.state.Ignition = false
	self.state.Starter = false
end

local function approach(current, target, rate, dt)
	local delta = target - current
	local step = math.abs(rate * dt)
	if math.abs(delta) <= step then return target end
	return current + (delta > 0 and step or -step)
end

function Engine:Step(dt, electricalAvailable)
	assert(type(dt) == "number" and dt >= 0, "Engine:Step requires a non-negative dt")
	local s = self.state
	local c = DEFAULTS

	if s.Running then
		local throttle = s.Throttle or 0
		local targetN1 = c.IdleN1 + throttle * (c.MaxN1 - c.IdleN1)
		local targetN2 = c.IdleN2 + throttle * (c.MaxN2 - c.IdleN2) * 0.15
		s.N1 = approach(s.N1, targetN1, c.SpoolUpRate, dt)
		s.N2 = approach(s.N2, targetN2, c.SpoolUpRate, dt)
		s.FuelFlow = c.MaxFuelFlow * (0.2 + throttle * 0.8)
		s.Thrust = math.clamp((s.N1 / 100) * (0.35 + throttle * 0.65), 0, c.MaxThrust)
		s.EGT = approach(s.EGT, c.IdleEGT + throttle * 250, 40, dt)
		s.OilPressure = approach(s.OilPressure, c.IdleOilPressure + throttle * (c.MaxOilPressure - c.IdleOilPressure), 25, dt)
		s.GeneratorAvailable = electricalAvailable == true and s.N2 >= 50

		if not s.FuelOn then
			s.Running = false
			s.GeneratorAvailable = false
		end
	else
		if s.Starter and electricalAvailable then
			s.N2 = approach(s.N2, c.StarterMaxN2, c.StarterN2Rate, dt)
		else
			s.N2 = approach(s.N2, 0, c.SpoolDownRate, dt)
		end

		if s.Starter and s.FuelOn and s.Ignition and s.N2 >= c.LightOffN2 then
			s.Running = true
			s.StartFailed = false
			s.EGT = math.max(s.EGT, c.StartEGTPeak * 0.55)
		elseif s.Starter and s.FuelOn and s.N2 >= c.MinStartN2 and not s.Ignition then
			s.StartFailed = false
		end

		s.N1 = approach(s.N1, 0, c.SpoolDownRate, dt)
		s.FuelFlow = 0
		s.Thrust = 0
		s.OilPressure = approach(s.OilPressure, 0, 30, dt)
		s.EGT = approach(s.EGT, 20, 30, dt)
		s.GeneratorAvailable = false
	end

	return s
end

return Engine
