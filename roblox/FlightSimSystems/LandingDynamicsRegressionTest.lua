-- LandingDynamics regression tests v1.0
local State=require(script.Parent.State)
local LandingDynamics=require(script.Parent.LandingDynamics)
local Test={}
local function check(condition,message)
 if not condition then error(message,2) end
end
function Test.Run()
 local state=State.new()
 local dynamics=LandingDynamics.new(state)
 state.GroundContact=false
 state.GearStatus={DownLocked=true}
 state.Airspeed=140
 state.VerticalSpeed=-120
 dynamics:Step(0.1)
 check(state.Landing.Touchdown==false,"initial airborne state incorrectly triggered touchdown")

 -- Ground contact without down-locked gear must not create a normal touchdown event.
 state.GroundContact=true
 state.GearStatus={DownLocked=false}
 dynamics:Step(0.1)
 check(state.Landing.WheelContact==false,"wheel contact reported with gear not down")
 check(state.Landing.Touchdown==false,"touchdown triggered from raw ground contact with gear up")

 -- Transition into actual wheel contact must trigger exactly one touchdown event.
 state.GearStatus={DownLocked=true}
 state.VerticalSpeed=-180
 dynamics:Step(0.1)
 check(state.Landing.WheelContact==true,"wheel contact was not established with gear down")
 check(state.Landing.Touchdown==true,"touchdown did not trigger on wheel-contact transition")
 check(state.Landing.TouchdownQuality=="FIRM","touchdown quality was not classified from sink rate")

 dynamics:Step(0.1)
 check(state.Landing.Touchdown==false,"touchdown event repeated without a new contact transition")
 check(state.Landing.TouchdownEvent==true,"touchdown event window ended too early")

 -- Leaving wheel contact resets the transition detector.
 state.GroundContact=false
 dynamics:Step(0.1)
 check(state.Landing.WheelContact==false,"wheel contact remained active after leaving ground")

 return true
end
return Test
