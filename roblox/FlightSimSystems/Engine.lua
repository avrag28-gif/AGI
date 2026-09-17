-- FlightSim engine runtime module v0.9
-- Simulation approximation. FuelFlow is expressed as kg/min and is consumed by Fuel.lua.
-- Generator availability is derived from engine N2; starter ignition is gated by electrical power and fuel path.
local Config = require(script.Parent.Config)
local Engine = {}
Engine.__index = Engine

local function approach(value, target, rate, dt)
	local delta = target - value
	local step = math.max(0, rate) * dt
	if math.abs(delta) <= step then return target end
	return value + (delta > 0 and step or -step)
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

	for index = 1, 2 do
		local e = x.Engines[index]
		local failure = failures[index]
		local throttle = math.clamp(tonumber((x.Throttle or {})[index]) or 0, 0, 1)
		local fuelAvailable = (x.Fuel and x.Fuel.Total or 0) > 0
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
			-- kg/min simulation flow. Fuel.lua converts this to kg for the current timestep.
			e.FuelFlow = math.max(0, e.N1 * (20 + 12 * throttle))

			local penalty = tonumber(antiIce.EnginePenalty and antiIce.EnginePenalty[index]) or 1
			penalty = math.clamp(penalty, 0.85, 1)
			e.Thrust = (e.N1 / 100) * (Config.MaxThrust / 2) * penalty
			e.GeneratorAvailable = e.N2 >= 50
		else
			e.N1 = approach(e.N1, 0, 18, dt)
			e.EGT = approach(e.EGT, 20, 120, dt)
			e.OilPressure = approach(e.OilPressure, 0, 45, dt)
			e.FuelFlow = 0
			e.Thrust = 0
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
