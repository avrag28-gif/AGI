-- Regression test for Engine.FuelFlow -> Fuel tank consumption contract.
-- Run inside Roblox Studio with the FlightSimSystems modules available.
local State = require(script.Parent.Parent.State)
local Engine = require(script.Parent.Parent.Engine)
local Fuel = require(script.Parent.Parent.Fuel)
local Profile = require(script.Parent.Parent.AircraftProfile)

local function assertNear(actual, expected, tolerance, message)
	assert(math.abs(actual - expected) <= tolerance, message .. string.format(" (actual=%.6f expected=%.6f)", actual, expected))
end

local maxFuel = Profile.Weights.MaxUsableFuelMassKg
local state = State.new()
state.Electrical.Bus1 = true
state.Fuel.Left = 5000
state.Fuel.Center = maxFuel - 10000
state.Fuel.Right = 5000
state.Fuel.Total = maxFuel
state.FuelSystem.LeftPumpSwitch = true
state.FuelSystem.CenterPumpSwitch = true
state.FuelSystem.RightPumpSwitch = true
state.FuelSystem.EngineFeed[1] = "LEFT"
state.FuelSystem.EngineFeed[2] = "RIGHT"
state.Engines[1].Running = true
state.Engines[2].Running = true
state.Engines[1].FuelOn = true
state.Engines[2].FuelOn = true
state.Engines[1].N1 = 50
state.Engines[2].N1 = 50
state.Throttle[1] = 0.5
state.Throttle[2] = 0.5

local engine = Engine.new(state)
local fuel = Fuel.new(state)
local dt = 1

engine:Step(dt)
local flow1 = state.Engines[1].FuelFlow
local flow2 = state.Engines[2].FuelFlow
assert(flow1 > 0 and flow2 > 0, "running engines must produce positive fuel flow")

local beforeLeft = state.Fuel.Left
local beforeRight = state.Fuel.Right
local beforeTotal = state.Fuel.Total
fuel:Step(dt)

assertNear(beforeLeft - state.Fuel.Left, flow1 / 60, 1e-6, "engine 1 fuel flow must consume LEFT tank at kg/min")
assertNear(beforeRight - state.Fuel.Right, flow2 / 60, 1e-6, "engine 2 fuel flow must consume RIGHT tank at kg/min")
assertNear(beforeTotal - state.Fuel.Total, (flow1 + flow2) / 60, 1e-6, "total fuel must decrease by both engine flows")
assert(state.Fuel.Total <= maxFuel, "fuel total must never exceed the aircraft usable-fuel limit")
assert(state.Engines[1].FuelOn == true and state.Engines[2].FuelOn == true, "fuel consumption must not toggle cockpit FuelOn")

print("EngineFuelConsumptionRegressionTest PASS")
