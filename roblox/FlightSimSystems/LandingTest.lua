-- FlightSim landing contract tests v0.1
-- Deterministic state-level checks; not a Roblox TestService runner.
local LandingTest={}
local function expect(ok,msg) if not ok then error(msg,2) end end
function LandingTest.Run(state)
 local x=state:Get(); x.GroundContact=true; x.Airspeed=100; x.VerticalSpeed=0
 x.GearStatus={DownLocked=true}; x.Landing=x.Landing or {}
 x.Landing.Touchdown=false; x.Landing.TouchdownEvent=false; x.Landing.TouchdownQuality="NONE"
 local Dynamics=require(script.Parent.LandingDynamics).new(state)
 Dynamics.lastGround=true
 Dynamics:Step(0.1)
 expect(x.Landing.WheelContact==true,"wheel contact should be true with ground and gear down")
 x.GroundContact=false; x.Airspeed=130; x.VerticalSpeed=-3
 Dynamics:Step(0.1)
 expect(x.Landing.Touchdown==false,"liftoff must not create touchdown")
 x.GroundContact=true
 Dynamics:Step(0.1)
 expect(x.Landing.Touchdown==true,"ground transition must create touchdown")
 expect(x.Landing.TouchdownEvent==true,"touchdown event must persist briefly")
 expect(x.Landing.TouchdownQuality=="FIRM","sink-rate classification should be firm")
 Dynamics:Step(0.5)
 expect(x.Landing.TouchdownEvent==true,"event should still be active before timeout")
 Dynamics:Step(0.6)
 expect(x.Landing.TouchdownEvent==false,"event should expire")
 expect(x.Landing.TouchdownQuality=="FIRM","quality should persist after event timeout")
 return true
end
return LandingTest
