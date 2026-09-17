-- Hydraulic failure / control-authority regression tests v0.1
local State=require(script.Parent.State)
local Hydraulic=require(script.Parent.Hydraulic)
local Config=require(script.Parent.Config)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end
function Test.Run()
	local state=State.new()
	state.Engines[1].Running=true
	state.Engines[2].Running=true
	state.Electrical.Bus1=true
	state.Electrical.Bus2=true
	state.Hydraulic.A.Pressure=3000
	state.Hydraulic.B.Pressure=3000
	state.Hydraulic.Standby.Pressure=0
	state.HydraulicDemand.FlightControls=0.6
	state.HydraulicDemand.FlightControlsA=0.5
	state.HydraulicDemand.FlightControlsB=0.6
	state.HydraulicDemand.LandingGear=0
	state.HydraulicDemand.Brakes=0
	local hydraulic=Hydraulic.new(state,Config)

	-- Both primary systems healthy: standby must not become an automatic source.
	hydraulic:Step(0.1)
	check(state.Hydraulic.A.Pressure>0,"System A lost pressure unexpectedly")
	check(state.Hydraulic.B.Pressure>0,"System B lost pressure unexpectedly")
	check(state.Hydraulic.Standby.ElectricPump==false,"standby pump activated with both primary systems available")

	-- System A failure: A must go to zero while B continues supplying its demand.
	state.Failures.Hydraulic={A=true,B=false}
	state.Hydraulic.A.Pressure=3000
	state.Hydraulic.B.Pressure=3000
	hydraulic:Step(0.1)
	check(state.Hydraulic.A.Pressure==0,"failed System A retained hydraulic pressure")
	check(state.Hydraulic.A.Available==false,"failed System A remained available")
	check(state.Hydraulic.B.Pressure>0,"healthy System B lost pressure after A failure")
	check(state.HydraulicState.FailureA==true,"System A failure was not published")

	-- With A failed, automatic standby support is permitted for control demand.
	check(state.Hydraulic.Standby.ElectricPump==true,"standby pump did not support control demand after primary failure")
	check(state.Hydraulic.Standby.PumpDemand>0,"standby control demand was not propagated")

	-- Removing all flight-control demand must release standby demand even while A is failed.
	state.HydraulicDemand.FlightControls=0
	hydraulic:Step(0.1)
	check(state.Hydraulic.Standby.ElectricPump==false,"standby pump remained active after control demand was removed")

	return true
end
return Test
