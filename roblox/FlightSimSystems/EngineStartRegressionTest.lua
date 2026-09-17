-- Engine start regression tests v1.0
-- Guards electrical and fuel-path interlocks against false engine starts.
local State = require(script.Parent.State)
local Engine = require(script.Parent.Engine)
local Test = {}

local function check(condition, message)
	if not condition then error(message, 2) end
end

function Test.Run()
	-- No electrical bus: starter command must not create a running engine.
	local noPower = State.new()
	local engineA = Engine.new(noPower)
	noPower.Engines[1].Starter = true
	noPower.Engines[1].FuelOn = true
	noPower.Engines[1].Ignition = true
	noPower.Fuel.Total = 10000
	noPower.FuelSystem.EngineFuelAvailable[1] = true
	engineA:Step(2)
	check(noPower.Engines[1].Running == false, "engine started without electrical starter power")

	-- Electrical bus but no fuel path: starter may spool, but ignition must not light off.
	local noFuelPath = State.new()
	local engineB = Engine.new(noFuelPath)
	noFuelPath.Electrical.Bus1 = true
	noFuelPath.Engines[1].Starter = true
	noFuelPath.Engines[1].FuelOn = true
	noFuelPath.Engines[1].Ignition = true
	noFuelPath.Fuel.Total = 10000
	noFuelPath.FuelSystem.EngineFuelAvailable[1] = false
	engineB:Step(2)
	check(noFuelPath.Engines[1].Running == false, "engine started without an available fuel path")

	-- Both interlocks available: engine may light off once starter N2 reaches StartN2.
	local valid = State.new()
	local engineC = Engine.new(valid)
	valid.Electrical.Bus1 = true
	valid.Engines[1].Starter = true
	valid.Engines[1].FuelOn = true
	valid.Engines[1].Ignition = true
	valid.Fuel.Total = 10000
	valid.FuelSystem.EngineFuelAvailable[1] = true
	engineC:Step(2)
	check(valid.Engines[1].Running == true, "engine failed to start with electrical power and fuel path")

	return true
end

return Test
