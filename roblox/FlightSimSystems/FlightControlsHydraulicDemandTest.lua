-- FlightSim hydraulic/control-authority regression tests v1.5
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Hydraulic=require(script.Parent.Hydraulic)
local Failures=require(script.Parent.Failures)
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
 local highAoA=newState(); highAoA.AoA=18; highAoA.Controls.Elevator=1; FlightControls.new(highAoA):Step(0.1); check(highAoA.ControlFeel.HighAoAAuthority<0.6,"high-AoA control-effectiveness telemetry did not degrade"); check(highAoA.ControlFeel.ElevatorAuthority>0.5,"high-AoA aerodynamic degradation incorrectly erased hydraulic authority")
 local lowSpeed=newState(); lowSpeed.Airspeed=40; lowSpeed.Controls.Aileron=1; lowSpeed.Controls.Elevator=1; FlightControls.new(lowSpeed):Step(0.1)
 check(math.abs(lowSpeed.Surface.Aileron)>0.80,"low-speed aileron surface travel was incorrectly airspeed-limited"); check(math.abs(lowSpeed.Surface.Elevator)>0.80,"low-speed elevator surface travel was incorrectly airspeed-limited"); check(lowSpeed.ControlFeel.DynamicAuthority<0.7,"dynamic-authority telemetry did not reflect low speed")
 local standby=newState(); standby.Controls.Rudder=1; standby.Hydraulic.A.Pressure=0; standby.Hydraulic.B.Pressure=0; standby.Hydraulic.Standby.Pressure=3000; FlightControls.new(standby):Step(0.1)
 check(math.abs(standby.Surface.Rudder)>0.20,"standby hydraulic rudder authority was not applied"); check(math.abs(standby.Surface.Aileron)<=0.13,"standby hydraulic pressure incorrectly restored aileron authority"); check(math.abs(standby.Surface.Elevator)<=0.13,"standby hydraulic pressure incorrectly restored elevator authority")
 local standbyChargedPrimaryHealthy=newState(); standbyChargedPrimaryHealthy.Controls.Rudder=1; standbyChargedPrimaryHealthy.Hydraulic.Standby.Pressure=3000; FlightControls.new(standbyChargedPrimaryHealthy):Step(0.1)
 check(math.abs(standbyChargedPrimaryHealthy.Surface.Rudder)>0.80,"healthy primary rudder authority was unexpectedly reduced")
 check(standbyChargedPrimaryHealthy.ControlFeel.RudderAuthority>0.90,"healthy primary rudder authority was incorrectly capped by standby logic")
 local airborneDamper=newState(); airborneDamper.Controls.YawDamper=true; airborneDamper.Sideslip=6; FlightControls.new(airborneDamper):Step(0.1); check(airborneDamper.ControlFeel.YawDamperActive==true,"airborne yaw damper was not marked active"); check(airborneDamper.Surface.Rudder<0,"airborne yaw damper did not provide correcting rudder input")
 local groundDamper=newState(); groundDamper.GroundContact=true; groundDamper.Airspeed=25; groundDamper.Controls.YawDamper=true; groundDamper.Sideslip=6; groundDamper.YawRate=5; FlightControls.new(groundDamper):Step(0.1); check(groundDamper.ControlFeel.YawDamperActive==false,"yaw damper remained active in the ground-control path"); check(math.abs(groundDamper.Surface.Rudder)<0.01,"ground yaw damper incorrectly injected rudder input")
 local hydraulicState=newState(); hydraulicState.Engines[1].Running=true; hydraulicState.Engines[2].Running=true; hydraulicState.Electrical.Bus1=true; hydraulicState.Electrical.Bus2=true; hydraulicState.Hydraulic.A.Pressure=0; hydraulicState.Hydraulic.B.Pressure=0; hydraulicState.Hydraulic.Standby.Pressure=0; hydraulicState.HydraulicDemand.FlightControls=1; hydraulicState.HydraulicDemand.FlightControlsA=1; hydraulicState.HydraulicDemand.FlightControlsB=1; hydraulicState.HydraulicDemand.FlightControlsStandby=0; Hydraulic.new(hydraulicState,Config):Step(0.1)
 check(hydraulicState.HydraulicDemand.Standby==0,"standby hydraulic demand was incorrectly derived from primary-only flight-control load")
 check(hydraulicState.Hydraulic.Standby.PumpDemand==0,"standby pump was driven by unsupported aileron/elevator demand")
 hydraulicState.HydraulicDemand.FlightControlsStandby=1; Hydraulic.new(hydraulicState,Config):Step(0.1)
 check(hydraulicState.Hydraulic.Standby.PumpDemand>0,"supported standby control demand did not drive standby pump")
 -- Failure manager publishes the hydraulic failure before FlightControls in the
 -- runtime. FlightControls must not wait for the next Hydraulic step to react.
 local immediateFailure=newState(); immediateFailure.Controls.Aileron=1; immediateFailure.Controls.Elevator=1
 Failures.new(immediateFailure):SetHydraulic("A",true); Failures.new(immediateFailure):SetHydraulic("B",true); Failures.new(immediateFailure):Step(0.1); FlightControls.new(immediateFailure):Step(0.1)
 check(immediateFailure.ControlFeel.HydraulicA==0,"declared hydraulic-A failure was not applied immediately")
 check(immediateFailure.ControlFeel.HydraulicB==0,"declared hydraulic-B failure was not applied immediately")
 check(math.abs(immediateFailure.Surface.Aileron)<=0.13,"declared dual hydraulic failure left excess aileron authority for one tick")
 check(math.abs(immediateFailure.Surface.Elevator)<=0.13,"declared dual hydraulic failure left excess elevator authority for one tick")
 check(immediateFailure.HydraulicDemand.FlightControls>0,"declared hydraulic failure incorrectly erased control demand")
 return true
end
return Test
