-- Hydraulic integration regression tests v1.1
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

	-- Standby must remain off with no flight-control demand.
	local hydraulic=Hydraulic.new(state,Config)
	state.Hydraulic.Standby.Pressure=0
	state.HydraulicDemand.Standby=0
	state.HydraulicDemand.FlightControls=0
	state.Failures.Hydraulic={A=true,B=true}
	state.Electrical.Bus1=true
	hydraulic:Step(0.1)
	check(state.Hydraulic.Standby.ElectricPump==false,"standby pump activated without flight-control demand")
	check(state.HydraulicState.SourceStandby=="NONE","standby source reported active without demand")

	-- Regression: State initializes Standby demand to 0, so automatic fallback must
	-- still engage when both primary systems are unavailable and controls demand exists.
	state.HydraulicDemand.FlightControls=0.5
	hydraulic:Step(0.1)
	check(state.Hydraulic.Standby.ElectricPump==true,"standby pump did not engage for automatic backup demand")
	check(state.Hydraulic.Standby.PumpDemand>0,"standby pump demand was not propagated")

	-- Removing the control demand must release the automatic standby request.
	state.HydraulicDemand.FlightControls=0
	hydraulic:Step(0.1)
	check(state.Hydraulic.Standby.ElectricPump==false,"standby pump remained active after demand removal")

	return true
end
return Test
