-- Flight-control hydraulic isolation regression tests v1.0
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local Test={}
local function check(condition,message)
 if not condition then error(message,2) end
end
function Test.Run()
 local state=State.new()
 state.GroundContact=false
 state.Airspeed=140
 state.Controls.Aileron=1
 state.Controls.Elevator=0
 state.Controls.Rudder=0
 local controls=FlightControls.new(state)

 -- Both primary systems available: full primary authority.
 state.Hydraulic.A.Pressure=1800
 state.Hydraulic.B.Pressure=1800
 state.Hydraulic.Standby.Pressure=0
 controls:Step(0.1)
 local full=math.abs(state.Surface.Aileron)
 check(full>0.5,"full hydraulic authority did not produce strong aileron response")

 -- A failure must not remove all control authority when B remains available.
 state.Hydraulic.A.Pressure=0
 state.Hydraulic.B.Pressure=1800
 controls:Step(0.1)
 check(math.abs(state.Surface.Aileron)>0.05,"single hydraulic-system loss removed all aileron authority")

 -- Standby pressure must not act as a universal replacement for ailerons.
 state.Hydraulic.B.Pressure=0
 state.Hydraulic.Standby.Pressure=1800
 controls:Step(0.1)
 check(math.abs(state.Surface.Aileron)<full,"standby incorrectly restored full aileron authority")
 check(state.ControlFeel.HydraulicStandby>0,"standby pressure was not reported")

 -- Manual reversion is explicitly limited and must be visible in state.
 check(state.ControlFeel.ManualReversion==true,"manual reversion state was not reported with both primary systems unavailable")
 check(math.abs(state.Surface.Aileron)>0,"manual reversion produced no residual aileron response")

 -- Rudder may receive limited standby assistance in this simulation contract.
 state.Controls.Aileron=0
 state.Controls.Rudder=1
 controls:Step(0.1)
 check(math.abs(state.Surface.Rudder)>0,"rudder lost all response with standby pressure available")

 -- Hydraulic demand must remain based on commanded load, not achieved pressure.
 state.Controls.Aileron=1
 state.Controls.Rudder=0
 controls:Step(0.1)
 check(state.HydraulicDemand.FlightControls>0,"flight-control hydraulic demand collapsed under hydraulic failure")
 return true
end
return Test
