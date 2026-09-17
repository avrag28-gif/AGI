-- Fuel system regression tests v1.0
-- Intended for Roblox Studio/TestEZ-style execution in the simulator test harness.
local State = require(script.Parent.State)
local Fuel = require(script.Parent.Fuel)

local function expect(condition, message)
	assert(condition, message)
end

local function newFuelState()
	local state = State.new()
	state.Electrical.ExternalPower = true
	state.FuelSystem.LeftPumpSwitch = false
	state.FuelSystem.CenterPumpSwitch = false
	state.FuelSystem.RightPumpSwitch = false
	state.FuelSystem.CrossfeedSwitch = false
	state.FuelSystem.EngineFeed[1] = "AUTO"
	state.FuelSystem.EngineFeed[2] = "AUTO"
	return state
end

-- Cold-and-dark/default safety: switches and effective pumps stay OFF.
do
	local state = State.new()
	local fuel = Fuel.new(state)
	fuel:Step(1)
	expect(state.FuelSystem.LeftPump == false, "Left pump must remain OFF by default")
	expect(state.FuelSystem.CenterPump == false, "Center pump must remain OFF by default")
	expect(state.FuelSystem.RightPump == false, "Right pump must remain OFF by default")
	expect(state.FuelSystem.EngineFuelAvailable[1] == false, "Engine 1 feed must be unavailable with pumps OFF")
end

-- A pump switch should create a valid feed path when an electrical source is live.
do
	local state = newFuelState()
	state.FuelSystem.LeftPumpSwitch = true
	state.Engines[1].Running = true
	state.Engines[1].FuelOn = true
	state.Engines[1].FuelFlow = 100
	local fuel = Fuel.new(state)
	fuel:Step(1)
	expect(state.FuelSystem.LeftPump == true, "Left pump should become effective with power")
	expect(state.FuelSystem.EngineFuelAvailable[1] == true, "Engine 1 should have a valid feed path")
	expect(state.FuelSystem.EngineFuelStarved[1] == false, "Engine 1 should not be starved with fuel available")
end

-- Starvation must not silently move the cockpit FuelOn switch.
do
	local state = newFuelState()
	state.Fuel.Left = 0
	state.Fuel.Center = 0
	state.Fuel.Right = 0
	state.Fuel.Total = 0
	state.FuelSystem.LeftQuantity = 0
	state.FuelSystem.CenterQuantity = 0
	state.FuelSystem.RightQuantity = 0
	state.FuelSystem.TotalQuantity = 0
	state.FuelSystem.LeftPumpSwitch = true
	state.Engines[1].Running = true
	state.Engines[1].FuelOn = true
	state.Engines[1].FuelFlow = 100
	local fuel = Fuel.new(state)
	fuel:Step(1)
	expect(state.FuelSystem.EngineFuelStarved[1] == true, "Engine 1 starvation should be reported")
	expect(state.Engines[1].FuelOn == true, "FuelOn must remain a cockpit command, not be cleared by starvation")
end

return true
