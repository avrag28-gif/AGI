-- Physics force-integration regression tests v0.4
local State=require(script.Parent.State)
local Physics=require(script.Parent.Physics)
local FlightControls=require(script.Parent.FlightControls)
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
 local balanced=baseState()
 Physics.new(balanced):Step(1/60)
 check(balanced.EngineIntegration.EngineOut==false,"two running engines must not be flagged engine-out merely because thrust is low")

 local failed=baseState()
 failed.Engines[2].Running=false
 failed.Engines[2].Thrust=0
 Physics.new(failed):Step(1/60)
 check(failed.EngineIntegration.EngineOut==true,"one running engine and one stopped engine must flag engine-out")
 check(math.abs(failed.EngineIntegration.YawRateContribution)<=5,"engine-out yaw contribution must remain bounded")
 check(failed.YawRate<0,"right-engine loss must produce a bounded left-yaw tendency in this sign convention")

 local failedOther=baseState()
 failedOther.Engines[1].Running=false
 failedOther.Engines[1].Thrust=0
 Physics.new(failedOther):Step(1/60)
 check(failedOther.EngineIntegration.EngineOut==true,"left-engine loss must flag engine-out")
 check(failedOther.YawRate>0,"left-engine loss must produce a bounded right-yaw tendency in this sign convention")

 local level=baseState()
 level.Pitch=0
 local climb=baseState()
 climb.Pitch=10
 Physics.new(level):Step(1/60)
 Physics.new(climb):Step(1/60)
 check(climb.Airspeed<level.Airspeed,"positive flight-path angle must reduce longitudinal acceleration through gravity")

 local lowLift=baseState()
 lowLift.Airspeed=90
 lowLift.WeatherEffects.EffectiveAirspeed=90
 lowLift.Pitch=0
 lowLift.Surface.Elevator=-1
 Physics.new(lowLift):Step(1/60)
 check(lowLift.VerticalSpeed<0,"lift below weight must produce downward vertical acceleration")

 local normal=baseState()
 normal.Surface.Aileron=1
 normal.AoA=8
 Physics.new(normal):Step(1/60)
 local normalRoll=math.abs(normal.RollRate)
 local stallState=baseState()
 stallState.Surface.Aileron=1
 stallState.Pitch=30
 Physics.new(stallState):Step(1/60)
 check(stallState.EngineIntegration.StallControlFactor<normal.EngineIntegration.StallControlFactor,"stall must reduce aerodynamic control effectiveness")
 check(math.abs(stallState.RollRate)<normalRoll,"stall must reduce aileron roll response")

 -- Hydraulic/control-surface integration: trim modifies the authoritative
 -- elevator surface once, and Physics consumes that surface without adding
 -- TrimPitch a second time.
 local trimState=baseState()
 trimState.Controls.Elevator=0
 trimState.TrimPitch=5
 trimState.Hydraulic.A.Pressure=3000
 trimState.Hydraulic.B.Pressure=3000
 FlightControls.new(trimState):Step(0.1)
 check(trimState.Surface.Elevator>0.35,"pitch trim did not produce the expected bounded elevator contribution")
 local neutralTrim=baseState()
 neutralTrim.Controls.Elevator=0
 neutralTrim.TrimPitch=0
 FlightControls.new(neutralTrim):Step(0.1)
 check(math.abs(trimState.Surface.Elevator)>math.abs(neutralTrim.Surface.Elevator),"trim did not change elevator surface relative to neutral trim")

 -- Yaw is an attitude angle, while YawRate is angular rate. They must not
 -- share the same state value.
 local yawState=baseState()
 yawState.Yaw=10
 yawState.Heading=10
 yawState.Surface.Rudder=1
 Physics.new(yawState):Step(1/60)
 check(math.abs(yawState.Yaw-10)>0.0001,"yaw attitude must integrate from yaw rate")
 check(math.abs(yawState.Yaw-yawState.YawRate)>0.0001,"yaw angle must not be overwritten with yaw rate")
 return true
end
return {Run=run}
