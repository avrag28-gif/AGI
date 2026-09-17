-- Engine/fuel integration regression tests v1.0
-- Guards against stale fuel-path availability, fuel starvation and generator-state regressions.
local State=require(script.Parent.State)
local Fuel=require(script.Parent.Fuel)
local Engine=require(script.Parent.Engine)
local Test={}

local function check(condition,message)
	if not condition then error(message,2) end
end

local function configureColdStart(state)
	state.Electrical.Battery=true
	state.Electrical.Bus1=true
	state.Electrical.Bus2=true
	state.Electrical.ExternalPower=true
	state.Electrical.APU=true
	state.Fuel.Left=500
	state.Fuel.Center=500
	state.Fuel.Right=500
	state.Fuel.Total=1500
	state.FuelSystem.LeftPumpSwitch=true
	state.FuelSystem.CenterPumpSwitch=true
	state.FuelSystem.RightPumpSwitch=true
	state.FuelSystem.EngineFeed[1]="AUTO"
	state.FuelSystem.EngineFeed[2]="AUTO"
	state.FuelSystem.CrossfeedSwitch=false
	for i=1,2 do
		state.Engines[i].Starter=true
		state.Engines[i].FuelOn=true
		state.Engines[i].Ignition=true
	end
end

function Test.Run()
	local state=State.new()
	local fuel=Fuel.new(state)
	local engine=Engine.new(state)
	configureColdStart(state)

	-- Fuel path must be established before the engine is allowed to light.
	fuel:Step(1/60)
	check(state.FuelSystem.EngineFuelAvailable[1]==true,"Engine 1 fuel path was not available")
	check(state.FuelSystem.EngineFuelAvailable[2]==true,"Engine 2 fuel path was not available")

	engine:Step(1.0)
	check(state.Engines[1].Running==true,"Engine 1 failed to start with valid fuel/electrical supply")
	check(state.Engines[2].Running==true,"Engine 2 failed to start with valid fuel/electrical supply")
	check(state.Engines[1].Thrust>0,"Engine 1 produced no thrust after start")
	check(state.Engines[2].Thrust>0,"Engine 2 produced no thrust after start")

	-- Remove all fuel and rebuild the feed state before the next engine step.
	state.Fuel.Left=0
	state.Fuel.Center=0
	state.Fuel.Right=0
	state.Fuel.Total=0
	fuel:Step(1/60)
	check(state.FuelSystem.EngineFuelAvailable[1]==false,"Engine 1 incorrectly retained fuel availability after tanks emptied")
	check(state.FuelSystem.EngineFuelAvailable[2]==false,"Engine 2 incorrectly retained fuel availability after tanks emptied")

	engine:Step(1.0)
	check(state.Engines[1].Running==false,"Engine 1 continued running after fuel starvation")
	check(state.Engines[2].Running==false,"Engine 2 continued running after fuel starvation")
	check(state.Engines[1].Thrust==0,"Engine 1 retained thrust after fuel starvation")
	check(state.Engines[2].Thrust==0,"Engine 2 retained thrust after fuel starvation")
	check(state.Engines[1].GeneratorAvailable==false,"Engine 1 generator remained available after shutdown")
	check(state.Engines[2].GeneratorAvailable==false,"Engine 2 generator remained available after shutdown")

	return true
end

return Test
