-- FlightSim engine runtime module v0.5
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
	local electrical = x.Electrical.Bus1 or x.Electrical.Bus2
	local fuelSystem = x.FuelSystem or {}

	for index = 1, 2 do
		local e = x.Engines[index]
		local throttle = math.clamp(tonumber(x.Throttle[index]) or 0, 0, 1)
		local fuelAvailable = (x.Fuel.Total or 0) > 0
		local fuelPathAvailable = fuelSystem.EngineFuelAvailable == nil or fuelSystem.EngineFuelAvailable[index] ~= false

		-- Starter: N2 is driven electrically until the starter cutoff region.
		if e.Starter and electrical and not e.Running then
			e.N2 = approach(e.N2, 25, 22, dt)
		else
			e.N2 = approach(e.N2, e.Running and (55 + 35 * throttle) or 0, e.Running and 12 or 5, dt)
		end

		-- Start sequence: starter + fuel + ignition + sufficient N2 + an available feed path produces light-off.
		if not e.Running and e.Starter and e.FuelOn and e.Ignition and fuelAvailable and fuelPathAvailable and e.N2 >= Config.StartN2 then
			e.Running = true
			e.StartFailed = false
	end

	-- Detect an invalid start attempt once N2 falls back without light-off.
	if not e.Running and e.Starter and e.FuelOn and e.Ignition and (not electrical or not fuelAvailable or not fuelPathAvailable) then
		e.StartFailed = true
	end

	-- Fuel cut, empty tanks, or loss of the selected feed path shuts the engine down.
	if e.Running and (not e.FuelOn or not fuelAvailable or not fuelPathAvailable) then
		e.Running = false
		e.Starter = false
	end

	if e.Running then
		local targetN1 = 18 + 82 * throttle
		local targetN2 = 58 + 34 * throttle
		e.N1 = approach(e.N1, targetN1, 18, dt)
		e.N2 = approach(e.N2, targetN2, 10, dt)

		-- Simplified but stateful turbine indications: EGT rises after light-off,
		-- oil pressure follows spool, and fuel flow follows N1/throttle.
		local targetEGT = 360 + 360 * throttle + math.max(0, throttle - 0.9) * 120
		e.EGT = approach(e.EGT, targetEGT, 220, dt)
		e.OilPressure = approach(e.OilPressure, 35 + 60 * (e.N2 / 100), 55, dt)
		e.FuelFlow = math.max(0, e.N1 * (20 + 12 * throttle))
		e.Thrust = (e.N1 / 100) * (Config.MaxThrust / 2)
		e.GeneratorAvailable = electrical and e.N2 >= 50
	else
		e.N1 = approach(e.N1, 0, 18, dt)
		e.EGT = approach(e.EGT, 20, 120, dt)
		e.OilPressure = approach(e.OilPressure, 0, 45, dt)
		e.FuelFlow = 0
		e.Thrust = 0
		e.GeneratorAvailable = false

		-- A failed/aborted start clears the starter after the spool decays.
		if e.StartFailed and e.N2 < 8 then
			e.Starter = false
	end

	-- Starter normally cuts out after successful light-off and self-sustaining spool.
	if e.Running and e.N2 >= 46 then
		e.Starter = false
	end
end

return Engine
