-- FlightSim hydraulic/control-authority regression tests v1.4
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Hydraulic=require(script.Parent.Hydraulic)
local Config=require(script.Parent.Config)
local Test={}
local function check(condition,message) if not condition then error(message,2) end end
local function newState()
 local state=State.new(); state.GroundContact=false; state.Airspeed=100; state.Controls.Aileron=0; state.Controls.Elevator=0; state.Controls.Rudder=0; state.Controls.YawDamper=false; state.Hydraulic.A.Pressure=3000; state.Hydraulic.B.Pressure=3000; state.Hydraulic.Standby.Pressure=0; return state
end
function Test.Run()
 local state=newState(); state.Controls.Aileron=1; state.Hydraulic.A.Pressure=0; state.Hydraulic.B.Pressure=0; FlightControls.new(state):Step(0.1)
 check(state.HydraulicDemand.FlightControls>0,"hydraulic demand collapsed to zero with low pressure"); check(state.HydraulicDemand.FlightControlsB>0,"A/B hydraulic demand did not preserve aileron load"); check(math.abs(state.Surface.Aileron)>0.05,"manual-reversion aileron authority was lost with both primary systems unpowered"); check(math.abs(state.Surface.Rudder)<0.01,"rudder incorrectly gained manual-reversion authority")
 local partial=newState(); partial.Controls.Aileron=1; partial.Controls.Elevator=1; partial.Hydraulic.A.Pressure=3000; partial.Hydraulic.B.Pressure=0; FlightControls.new(partial):Step(0.1)
 check(math.abs(partial.Surface.Aileron)>0.20,"single-primary hydraulic authority is too low"); check(math.abs(partial.Surface.Elevator)>0.20,"single-primary elevator authority is too low"); check(partial.ControlFeel.AileronAuthority>0.5,"aileron hydraulic authority was not reported"); check(partial.ControlFeel.ElevatorAuthority>0.5,"elevator hydraulic authority was not reported")
 local lowSpeed=newState(); lowSpeed.Airspeed=40; lowSpeed.Controls.Aileron=1; lowSpeed.Controls.Elevator=1; FlightControls.new(lowSpeed):Step(0.1)
 check(math.abs(lowSpeed.Surface.Aileron)>0.80,"low-speed aileron surface travel was incorrectly airspeed-limited"); check(math.abs(lowSpeed.Surface.Elevator)>0.80,"low-speed elevator surface travel was incorrectly airspeed-limited"); check(lowSpeed.ControlFeel.DynamicAuthority<0.7,"dynamic-authority telemetry did not reflect low speed")
 local standby=newState(); standby.Controls.Rudder=1; standby.Hydraulic.A.Pressure=0; standby.Hydraulic.B.Pressure=0; standby.Hydraulic.Standby.Pressure=3000; FlightControls.new(standby):Step(0.1)
 check(math.abs(standby.Surface.Rudder)>0.20,"standby hydraulic rudder authority was not applied"); check(math.abs(standby.Surface.Aileron)<=0.13,"standby hydraulic pressure incorrectly restored aileron authority"); check(math.abs(standby.Surface.Elevator)<=0.13,"standby hydraulic pressure incorrectly restored elevator authority")
 local airborneDamper=newState(); airborneDamper.Controls.YawDamper=true; airborneDamper.Sideslip=6; FlightControls.new(airborneDamper):Step(0.1); check(airborneDamper.ControlFeel.YawDamperActive==true,"airborne yaw damper was not marked active"); check(airborneDamper.Surface.Rudder<0,"airborne yaw damper did not provide correcting rudder input")
 local groundDamper=newState(); groundDamper.GroundContact=true; groundDamper.Airspeed=25; groundDamper.Controls.YawDamper=true; groundDamper.Sideslip=6; groundDamper.YawRate=5; FlightControls.new(groundDamper):Step(0.1); check(groundDamper.ControlFeel.YawDamperActive==false,"yaw damper remained active in the ground-control path"); check(math.abs(groundDamper.Surface.Rudder)<0.01,"ground yaw damper incorrectly injected rudder input")
 -- Standby pump must not be driven by aileron/elevator demand that the standby
 -- control path cannot use. Only the explicit supported standby demand may run it.
 local hydraulicState=newState(); hydraulicState.Engines[1].Running=true; hydraulicState.Engines[2].Running=true; hydraulicState.Electrical.Bus1=true; hydraulicState.Electrical.Bus2=true; hydraulicState.Hydraulic.A.Pressure=0; hydraulicState.Hydraulic.B.Pressure=0; hydraulicState.Hydraulic.Standby.Pressure=0; hydraulicState.HydraulicDemand.FlightControls=1; hydraulicState.HydraulicDemand.FlightControlsA=1; hydraulicState.HydraulicDemand.FlightControlsB=1; hydraulicState.HydraulicDemand.FlightControlsStandby=0; Hydraulic.new(hydraulicState,Config):Step(0.1)
 check(hydraulicState.HydraulicDemand.Standby==0,"standby hydraulic demand was incorrectly derived from primary-only flight-control load")
 check(hydraulicState.Hydraulic.Standby.PumpDemand==0,"standby pump was driven by unsupported aileron/elevator demand")
 hydraulicState.HydraulicDemand.FlightControlsStandby=1; Hydraulic.new(hydraulicState,Config):Step(0.1)
 check(hydraulicState.Hydraulic.Standby.PumpDemand>0,"supported standby control demand did not drive standby pump")
 return true
end
return Test
