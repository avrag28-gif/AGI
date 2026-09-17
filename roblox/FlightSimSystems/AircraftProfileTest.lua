-- Boeing 737-800 aircraft profile contract tests v1.0
local Profile=require(script.Parent.AircraftProfile)
local Test={}
local function check(c,m) if not c then error(m,2) end end
function Test.Run()
 check(Profile.Aircraft.Model=="737-800","wrong aircraft profile")
 check(Profile.Engine.Model=="CFM56-7B26","wrong baseline engine")
 check(Profile.Engine.EngineCount==2,"wrong engine count")
 check(Profile.Engine.TakeoffThrustLb==26300,"unexpected 7B26 takeoff thrust")
 check(Profile.Engine.MaxContinuousThrustLb==25900,"unexpected 7B26 maximum continuous thrust")
 check(Profile.Limits.VMOKcas==340,"unexpected VMO")
 check(Profile.Limits.MMO==0.82,"unexpected MMO")
 check(Profile.Hydraulics.NominalPressurePsi==3000,"unexpected hydraulic nominal pressure")
 return true
end
return Test
