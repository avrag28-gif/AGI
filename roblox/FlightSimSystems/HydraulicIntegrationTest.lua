-- Hydraulic integration regression tests v1.0
-- These tests target the structured Hydraulic.A/B/Standby state contract.
local State=require(script.Parent.State)
local Hydraulic=require(script.Parent.Hydraulic)
local LandingGear=require(script.Parent.LandingGear)
local Brakes=require(script.Parent.Brakes)
local Config=require(script.Parent.Config)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end
function Test.Run()
	-- Regression: A/B are structured records, so consumers must read .Pressure.
	local state=State.new()
	state.Hydraulic.A.Pressure=2200
	state.Hydraulic.B.Pressure=1800
	state.Gear.Nose=false
	state.Gear.Left=false
	state.Gear.Right=false
	state.GearPosition={Nose=1,Left=1,Right=1}
	state.Brakes.Parking=false

	local gear=LandingGear.new(state)
	gear:Step(0.1)
	check(state.GearStatus.HydraulicAvailable==true,"landing gear did not detect structured hydraulic pressure")
	check(state.GearPosition.Nose<1,"landing gear actuator did not move with available hydraulic pressure")

	local brakes=Brakes.new(state)
	state.Brakes.ToeBrake=1
	brakes:Step(0.1)
	check(state.Brakes.HydraulicAvailable==true,"brakes did not detect structured hydraulic pressure")
	check(state.Brakes.BrakePressure>0,"brakes did not build pressure with available hydraulic pressure")

	-- Standby remains off when there is no explicit standby demand.
	local hydraulic=Hydraulic.new(state,Config)
	state.Hydraulic.Standby.Pressure=0
	state.HydraulicDemand.Standby=0
	state.Electrical.Bus1=true
	hydraulic:Step(0.1)
	check(state.Hydraulic.Standby.ElectricPump==false,"standby pump activated without demand")
	check(state.HydraulicState.SourceStandby=="NONE","standby source reported active without demand")

	return true
end
return Test
