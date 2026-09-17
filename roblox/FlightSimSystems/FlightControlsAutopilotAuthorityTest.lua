-- FlightSim flight-control / autopilot authority regression tests v1.0
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Autopilot=require(script.Parent.Autopilot)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end
local function setup()
	local state=State.new()
	state.GroundContact=false
	state.Airspeed=180
	state.Altitude=10000
	state.Heading=0
	state.Navigation.Mode="HDG"
	state.Autopilot.Enabled=true
	state.Autopilot.TargetHeading=30
	state.Autopilot.TargetAltitude=10000
	state.Hydraulic.A.Pressure=3000
	state.Hydraulic.B.Pressure=3000
	state.Hydraulic.Standby.Pressure=0
	return state
end
function Test.Run()
	-- Full primary pressure must expose full control-group authority to AP.
	local healthy=setup()
	FlightControls.new(healthy):Step(0.1)
	Autopilot.new(healthy):Step(0.1)
	check(healthy.ControlFeel.AileronAuthority>0.95,"healthy aileron authority was not reported")
	check(healthy.ControlFeel.ElevatorAuthority>0.95,"healthy elevator authority was not reported")
	check(healthy.Autopilot.AuthorityLimited==false,"healthy hydraulics incorrectly limited AP")

	-- Hydraulic loss must propagate to the same authority gate consumed by AP.
	local failed=setup()
	failed.Hydraulic.A.Pressure=0
	failed.Hydraulic.B.Pressure=0
	FlightControls.new(failed):Step(0.1)
	Autopilot.new(failed):Step(0.1)
	check(failed.ControlFeel.AileronAuthority<0.2,"hydraulic loss did not reduce aileron authority")
	check(failed.ControlFeel.ElevatorAuthority<0.2,"hydraulic loss did not reduce elevator authority")
	check(failed.Autopilot.AuthorityLimited==true,"AP did not report hydraulic/control authority limitation")
	check(math.abs(failed.Autopilot.CommandAileron)<=1,"AP aileron command escaped normalized bounds")
	check(math.abs(failed.Autopilot.CommandElevator)<=1,"AP elevator command escaped normalized bounds")

	-- Standby pressure remains a rudder-only recovery path in this simulation;
	-- it must not make AP think primary pitch/roll authority is restored.
	local standby=setup()
	standby.Hydraulic.A.Pressure=0
	standby.Hydraulic.B.Pressure=0
	standby.Hydraulic.Standby.Pressure=3000
	FlightControls.new(standby):Step(0.1)
	Autopilot.new(standby):Step(0.1)
	check(standby.ControlFeel.RudderAuthority>0.8,"standby rudder authority was not available")
	check(standby.ControlFeel.AileronAuthority<0.2,"standby pressure incorrectly restored aileron authority")
	check(standby.ControlFeel.ElevatorAuthority<0.2,"standby pressure incorrectly restored elevator authority")
	check(standby.Autopilot.AuthorityLimited==true,"AP ignored lost primary pitch/roll authority")

	return true
end
return Test
