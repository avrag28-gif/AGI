-- LandingModel regression tests v0.1
-- Verifies that raw GroundContact cannot create normal ground/rollout state without wheel contact.
local State=require(script.Parent.State)
local LandingModel=require(script.Parent.LandingModel)
local Test={}
local function check(condition,message)
 if not condition then error(message,2) end
end
function Test.Run()
 local state=State.new()
 local model=LandingModel.new(state)
 state.GroundContact=false
 state.GearStatus.DownLocked=false
 state.Airspeed=120
 state.Altitude=100
 state.VerticalSpeed=-500
 model:Step(0.1)
 check(state.Landing.Phase=="AIRBORNE","gear-up aircraft was incorrectly classified as ground state")
 check(state.Landing.Rollout==false,"rollout activated without wheel contact")

 -- Raw ground contact with gear up must still remain airborne in the landing phase model.
 state.GroundContact=true
 model:Step(0.1)
 check(state.Landing.Phase=="AIRBORNE","raw GroundContact incorrectly created ground phase with gear up")
 check(state.Landing.Takeoff==false,"false takeoff event generated from non-wheel ground contact")

 -- Gear down + ground contact establishes wheel contact and normal ground state.
 state.GearStatus.DownLocked=true
 state.Airspeed=3
 model:Step(0.1)
 check(state.Landing.Phase=="GROUND","wheel contact did not create ground phase")
 check(state.Landing.Rollout==false,"low-speed ground state incorrectly marked rollout")

 -- Accelerating while remaining on wheels enters rollout.
 state.Airspeed=40
 model:Step(0.1)
 check(state.Landing.Phase=="ROLLOUT","wheel contact at rollout speed did not enter rollout phase")
 check(state.Landing.Rollout==true,"rollout flag was not asserted")

 -- Leaving wheel contact generates the takeoff transition.
 state.GroundContact=false
 state.Airspeed=80
 model:Step(0.1)
 check(state.Landing.Takeoff==true,"takeoff transition was not detected after wheel contact ended")
 check(state.Landing.Phase=="AIRBORNE","airborne phase was not restored after wheel contact ended")
 return true
end
return Test
