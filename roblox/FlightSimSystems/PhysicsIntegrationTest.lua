-- Physics force-integration regression tests v0.1
local State=require(script.Parent.State)
local Physics=require(script.Parent.Physics)
local function check(ok,msg) assert(ok,msg) end
local function baseState()
 local s=State.new()
 s.GroundContact=false
 s.Altitude=10000
 s.Airspeed=200
 s.WeatherEffects.EffectiveAirspeed=200
 s.WeatherEffects.WindUKts=0
 s.WeatherEffects.WindVKts=0
 s.Engines[1].Running=true
 s.Engines[2].Running=true
 s.Engines[1].Thrust=100000
 s.Engines[2].Thrust=100000
 return s
end
local function run()
 -- Both engines operating at low thrust must not be classified as an engine-out.
 local balanced=baseState()
 Physics.new(balanced):Step(1/60)
 check(balanced.EngineIntegration.EngineOut==false,"two running engines must not be flagged engine-out merely because thrust is low")

 -- A genuine asymmetric engine availability state must be detected.
 local failed=baseState()
 failed.Engines[2].Running=false
 failed.Engines[2].Thrust=0
 Physics.new(failed):Step(1/60)
 check(failed.EngineIntegration.EngineOut==true,"one running engine and one stopped engine must flag engine-out")

 -- A climb angle must consume longitudinal energy through gravity.
 local level=baseState()
 level.Pitch=0
 local climb=baseState()
 climb.Pitch=10
 Physics.new(level):Step(1/60)
 Physics.new(climb):Step(1/60)
 check(climb.Airspeed<level.Airspeed,"positive flight-path angle must reduce longitudinal acceleration through gravity")

 -- Vertical force integration must respond to lift/weight imbalance.
 local lowLift=baseState()
 lowLift.Airspeed=90
 lowLift.WeatherEffects.EffectiveAirspeed=90
 lowLift.Pitch=0
 lowLift.Surface.Elevator=-1
 Physics.new(lowLift):Step(1/60)
 check(lowLift.VerticalSpeed<0,"lift below weight must produce downward vertical acceleration")
 return true
end
return {Run=run}
