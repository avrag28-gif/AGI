-- FlightSim engine runtime module v1.1
-- Simulation approximation. FuelFlow is expressed as kg/min and is consumed by Fuel.lua.
-- CFM56-7B26 thrust rating is aircraft-profile data; the performance curve below is simulator tuning.
local Config = require(script.Parent.Config)
local Engine = {}
Engine.__index = Engine

local function approach(value, target, rate, dt)
	local delta = target - value
	local step = math.max(0, rate) * dt
	if math.abs(delta) <= step then return target end
	return value + (delta > 0 and step or -step)
end

local function clamp(v, a, b)
	return math.max(a, math.min(b, v))
end

local function finite(v, fallback)
	v = tonumber(v)
	if v and v == v and v ~= math.huge and v ~= -math.huge then
		return v
	end
	return fallback
end

local function isaTemperatureC(altitudeFt)
	-- ISA troposphere approximation, adequate for this game-simulation layer.
	return 15 - 1.9812 * math.max(0, altitudeFt) / 1000
end

local function thrustAvailableFactor(altitudeFt, ambientTempC, mach)
	-- Deliberately a smooth simulator approximation, not an engine-deck lookup.
	-- It captures the dominant trend: less available thrust with altitude and
	-- hot-day conditions, with a small ram-recovery benefit at speed.
	local altitude = clamp(math.max(0, altitudeFt) / 41000, 0, 1)
	local pressureFactor = math.exp(-1.15 * altitude)
	local isa = isaTemperatureC(altitudeFt)
	local hotPenalty = clamp(1 - math.max(0, ambientTempC - isa) * 0.006, 0.72, 1)
	local coldBenefit = clamp(1 + math.max(0, isa - ambientTempC) * 0.0015, 0.97, 1.04)
	local ram = clamp(1 + clamp(mach, 0, 0.82) * 0.12, 1, 1.10)
	return clamp(pressureFactor * hotPenalty * coldBenefit * ram, 0.18, 1.05)
end

function Engine.new(state)
	return setmetatable({state = state}, Engine)
end

function Engine:Step(dt)
	local x = self.state:Get()
	local electrical = ((x.Electrical or {}).Bus1 == true) or ((x.Electrical or {}).Bus2 == true)
	local fuelSystem = x.FuelSystem or {}
	local failures = x.Failures and x.Failures.Engines or {}
	local antiIce = x.AntiIce or {}
	local environment = x.Environment or {}
	local weather = x.WeatherEffects or {}
	local altitudeFt = math.max(0, finite(x.Altitude, 0))
	local ambientTempC = finite(environment.TemperatureC, finite(weather.TemperatureC, 15 - 1.9812 * altitudeFt / 1000))
	local mach = clamp(finite(x.Mach, (finite(x.Airspeed, 0) / 661.47)), 0, 0.90)
	local availableFactor = thrustAvailableFactor(altitudeFt, ambientTempC, mach)

	for index = 1, 2 do
		local e = x.Engines[index]
		local failure = failures[index]
		local throttle = clamp(finite((x.Throttle or {})[index], 0), 0, 1)
		local fuelAvailable = finite((x.Fuel or {}).Total, 0) > 0
		local fuelPathAvailable = fuelSystem.EngineFuelAvailable ~= nil and fuelSystem.EngineFuelAvailable[index] == true

		if failure and failure.Active then
			e.FuelOn = false
			e.Ignition = false
			e.Starter = false
			e.Running = false
			e.StartFailed = false
		end

		local usable = not (failure and failure.Active)
		if usable and e.Starter and electrical and not e.Running then
			e.N2 = approach(e.N2, 25, 22, dt)
		else
			e.N2 = approach(e.N2, e.Running and (55 + 35 * throttle) or 0, e.Running and 12 or 5, dt)
		end

		if usable and not e.Running and e.Starter and e.FuelOn and e.Ignition
			and electrical and fuelAvailable and fuelPathAvailable
			and e.N2 >= Config.StartN2 then
			e.Running = true
			e.StartFailed = false
		end

		if usable and not e.Running and e.Starter and e.FuelOn and e.Ignition
			and (not electrical or not fuelAvailable or not fuelPathAvailable) then
			e.StartFailed = true
		end

		if usable and e.Running and (not e.FuelOn or not fuelAvailable or not fuelPathAvailable) then
			e.Running = false
			e.Starter = false
		end

		if usable and e.Running then
			local targetN1 = 18 + 82 * throttle
			local targetN2 = 58 + 34 * throttle
			e.N1 = approach(e.N1, targetN1, 18, dt)
			e.N2 = approach(e.N2, targetN2, 10, dt)

			local targetEGT = 360 + 360 * throttle + math.max(0, throttle - 0.9) * 120
			e.EGT = approach(e.EGT, targetEGT, 220, dt)
			e.OilPressure = approach(e.OilPressure, 35 + 60 * (e.N2 / 100), 55, dt)

			local n1Fraction = clamp(e.N1 / 100, 0, 1)
			local idleFlow = 18
			local additionalFlow = 90 * (n1Fraction ^ 1.35)
			e.FuelFlow = idleFlow + additionalFlow * (0.65 + 0.35 * throttle)

			local penalty = finite(antiIce.EnginePenalty and antiIce.EnginePenalty[index], 1)
			penalty = clamp(penalty, 0.85, 1)
			local ratedThrust = Config.MaxThrust / 2
			e.AvailableThrustFactor = availableFactor
			e.Thrust = (e.N1 / 100) * ratedThrust * availableFactor * penalty
			e.GeneratorAvailable = e.N2 >= 50
		else
			e.N1 = approach(e.N1, 0, 18, dt)
			e.EGT = approach(e.EGT, 20, 120, dt)
			e.OilPressure = approach(e.OilPressure, 0, 45, dt)
			e.FuelFlow = 0
			e.Thrust = 0
			e.AvailableThrustFactor = availableFactor
			e.GeneratorAvailable = false
			if e.StartFailed and e.N2 < 8 then
				e.Starter = false
			end
		end

		if e.Running and e.N2 >= 46 then
			e.Starter = false
		end
	end
end

return Engine
