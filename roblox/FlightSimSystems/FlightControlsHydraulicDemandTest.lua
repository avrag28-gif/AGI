-- FlightSim hydraulic/control-authority regression tests v1.3
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end
local function newState()
	local state=State.new()
	state.GroundContact=false
	state.Airspeed=100
	state.Controls.Aileron=0
	state.Controls.Elevator=0
	state.Controls.Rudder=0
	state.Controls.YawDamper=false
	state.Hydraulic.A.Pressure=3000
	state.Hydraulic.B.Pressure=3000
	state.Hydraulic.Standby.Pressure=0
	return state
end
function Test.Run()
	-- Demand must remain pressure-independent: low pressure cannot erase the
	-- actuator load requested by the pilot/autopilot.
	local state=newState()
	state.Controls.Aileron=1
	state.Hydraulic.A.Pressure=0
	state.Hydraulic.B.Pressure=0
	local controls=FlightControls.new(state)
	controls:Step(0.1)
	check(state.HydraulicDemand.FlightControls>0,"hydraulic demand collapsed to zero with low pressure")
	check(state.HydraulicDemand.FlightControlsB>0,"A/B hydraulic demand did not preserve aileron load")
	check(math.abs(state.Surface.Aileron)>0.05,"manual-reversion aileron authority was lost with both primary systems unpowered")
	check(math.abs(state.Surface.Rudder)<0.01,"rudder incorrectly gained manual-reversion authority")

	-- With one primary system available, elevator/aileron authority should be
	-- substantially greater than the unpowered manual-reversion case.
	local partial=newState()
	partial.Controls.Aileron=1
	partial.Controls.Elevator=1
	partial.Hydraulic.A.Pressure=3000
	partial.Hydraulic.B.Pressure=0
	local partialControls=FlightControls.new(partial)
	partialControls:Step(0.1)
	check(math.abs(partial.Surface.Aileron)>0.20,"single-primary hydraulic authority is too low")
	check(math.abs(partial.Surface.Elevator)>0.20,"single-primary elevator authority is too low")
	check(partial.ControlFeel.AileronAuthority>0.5,"aileron hydraulic authority was not reported")
	check(partial.ControlFeel.ElevatorAuthority>0.5,"elevator hydraulic authority was not reported")

	-- Airspeed affects aerodynamic effectiveness in Physics, not hydraulic
	-- surface travel. A low-speed airborne command must not be attenuated twice.
	local lowSpeed=newState()
	lowSpeed.Airspeed=40
	lowSpeed.Controls.Aileron=1
	lowSpeed.Controls.Elevator=1
	lowSpeed.Hydraulic.A.Pressure=3000
	lowSpeed.Hydraulic.B.Pressure=3000
	local lowSpeedControls=FlightControls.new(lowSpeed)
	lowSpeedControls:Step(0.1)
	check(math.abs(lowSpeed.Surface.Aileron)>0.80,"low-speed aileron surface travel was incorrectly airspeed-limited")
	check(math.abs(lowSpeed.Surface.Elevator)>0.80,"low-speed elevator surface travel was incorrectly airspeed-limited")
	check(lowSpeed.ControlFeel.DynamicAuthority<0.7,"dynamic-authority telemetry did not reflect low speed")

	-- Standby hydraulic pressure can restore rudder authority, but must not
	-- silently restore the primary aileron/elevator manual-reversion path.
	local standby=newState()
	standby.Controls.Rudder=1
	standby.Hydraulic.A.Pressure=0
	standby.Hydraulic.B.Pressure=0
	standby.Hydraulic.Standby.Pressure=3000
	local standbyControls=FlightControls.new(standby)
	standbyControls:Step(0.1)
	check(math.abs(standby.Surface.Rudder)>0.20,"standby hydraulic rudder authority was not applied")
	check(math.abs(standby.Surface.Aileron)<=0.13,"standby hydraulic pressure incorrectly restored aileron authority")
	check(math.abs(standby.Surface.Elevator)<=0.13,"standby hydraulic pressure incorrectly restored elevator authority")

	-- Yaw damper is a separate rudder input path. It may modify airborne rudder
	-- commands, but it must not fight the ground-steering/rudder pedal path.
	local airborneDamper=newState()
	airborneDamper.Controls.Rudder=0
	airborneDamper.Controls.YawDamper=true
	airborneDamper.Sideslip=6
	airborneDamper.YawRate=0
	FlightControls.new(airborneDamper):Step(0.1)
	check(airborneDamper.ControlFeel.YawDamperActive==true,"airborne yaw damper was not marked active")
	check(airborneDamper.Surface.Rudder<0,"airborne yaw damper did not provide correcting rudder input")

	local groundDamper=newState()
	groundDamper.GroundContact=true
	groundDamper.Airspeed=25
	groundDamper.Controls.Rudder=0
	groundDamper.Controls.YawDamper=true
	groundDamper.Sideslip=6
	groundDamper.YawRate=5
	FlightControls.new(groundDamper):Step(0.1)
	check(groundDamper.ControlFeel.YawDamperActive==false,"yaw damper remained active in the ground-control path")
	check(math.abs(groundDamper.Surface.Rudder)<0.01,"ground yaw damper incorrectly injected rudder input")

	return true
end
return Test
