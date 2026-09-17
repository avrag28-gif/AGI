-- FlightControls hydraulic-demand regression tests v1.0
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end
function Test.Run()
	local state=State.new()
	state.GroundContact=false
	state.Airspeed=100
	state.Controls.Aileron=1
	state.Controls.Elevator=0
	state.Controls.Rudder=0
	state.Hydraulic.A.Pressure=0
	state.Hydraulic.B.Pressure=0
	state.Hydraulic.Standby.Pressure=0

	local controls=FlightControls.new(state)
	controls:Step(0.1)

	-- Regression: commanded actuator load must remain visible even when pressure is low.
	check(state.HydraulicDemand.FlightControls>0,"hydraulic demand collapsed to zero with low pressure")
	check(state.HydraulicDemand.FlightControlsB>0,"A/B hydraulic demand did not preserve aileron load")
	check(math.abs(state.Surface.Aileron)<0.01,"surface gained unrealistic authority without hydraulic pressure")

	return true
end
return Test
