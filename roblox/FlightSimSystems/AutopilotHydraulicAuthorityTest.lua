-- Autopilot hydraulic-authority normalization regression test v0.1
local State=require(script.Parent.State)
local Autopilot=require(script.Parent.Autopilot)
local Test={}
local function check(condition,message) if not condition then error(message,2) end end

function Test.Run()
 local state=State.new()
 state.GroundContact=false
 state.Airspeed=140
 state.Autopilot.Enabled=true
 state.Autopilot.Mode="HDG"
 state.Navigation.Mode="HDG"
 state.Navigation.CommandHeading=0
 state.Navigation.CommandAltitude=3000
 state.Heading=0
 state.Altitude=3000

 state.ControlFeel={AileronAuthority=1,ElevatorAuthority=1,RudderAuthority=1,HydraulicAuthority=1}
 Autopilot.new(state):Step(0.1)
 check(math.abs(state.Autopilot.HydraulicAuthority-1)<0.001,"normal hydraulic authority was incorrectly scaled")
 check(state.Autopilot.AuthorityLimited==false,"normal hydraulic authority was incorrectly marked limited")

 state.ControlFeel.HydraulicAuthority=0
 state.ControlFeel.AileronAuthority=0.1
 state.ControlFeel.ElevatorAuthority=0.1
 state.ControlFeel.RudderAuthority=0.1
 Autopilot.new(state):Step(0.1)
 check(state.Autopilot.HydraulicAuthority==0,"failed hydraulic authority was not preserved")
 check(state.Autopilot.AuthorityLimited==true,"failed hydraulic authority was not reported as limited")
 return true
end
return Test
