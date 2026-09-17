-- Physics force-integration regression tests v0.8
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
 s.Hydraulic.A.Pressure=3000
 s.Hydraulic.B.Pressure=3000
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
 check(failedOther.YawRate>0,"left-engine loss must produce a bounded right-yaw tendency in this sign convention")\n\n local idleFailed=baseState()\n idleFailed.Engines[2].Running=false\n idleFailed.Engines[2].Thrust=0\n idleFailed.Engines[1].Thrust=0\n Physics.new(idleFailed):Step(1/60)\n check(math.abs(idleFailed.EngineIntegration.YawRateContribution)<0.05,"zero-thrust engine failure must not create a large asymmetric yaw moment")\n check(math.abs(idleFailed.EngineIntegration.EngineYawMoment)<0.01,"engine yaw moment must be derived from actual thrust difference")

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

 local lowSpeedNormal=baseState()
 lowSpeedNormal.Airspeed=200
 lowSpeedNormal.WeatherEffects.EffectiveAirspeed=200
 lowSpeedNormal.Surface.Aileron=1
 Physics.new(lowSpeedNormal):Step(1/60)
 local lowSpeedRoll=math.abs(lowSpeedNormal.RollRate)
 local lowSpeedStall=baseState()
 lowSpeedStall.Airspeed=45
 lowSpeedStall.WeatherEffects.EffectiveAirspeed=45
 lowSpeedStall.Surface.Aileron=1
 Physics.new(lowSpeedStall):Step(1/60)
 check(lowSpeedStall.StallActive==true,"low-speed envelope must enter stall-active state")
 check(lowSpeedStall.EngineIntegration.StallControlFactor<=0.30,"stall-active envelope must clamp control effectiveness")
 check(math.abs(lowSpeedStall.RollRate)<lowSpeedRoll,"low-speed stall must reduce roll response")

 local banked=baseState()
 banked.Roll=30
 Physics.new(banked):Step(1/60)
 check(banked.AeroStability.RollRestoringRate<0,"positive bank must generate negative restoring roll rate")
 check(banked.RollRate<0,"positive bank must start rolling back toward wings level")

 local slipped=baseState()
 slipped.Sideslip=5
 Physics.new(slipped):Step(1/60)
 check(slipped.AeroStability.SideslipRollRate<0,"positive sideslip must generate a restoring roll tendency")

 local trimState=baseState()
 trimState.Controls.Elevator=0
 trimState.TrimPitch=5
 FlightControls.new(trimState):Step(0.1)
 check(trimState.Surface.Elevator>0.35,"pitch trim did not produce the expected bounded elevator contribution")
 local neutralTrim=baseState()
 neutralTrim.Controls.Elevator=0
 neutralTrim.TrimPitch=0
 FlightControls.new(neutralTrim):Step(0.1)
 check(math.abs(trimState.Surface.Elevator)>math.abs(neutralTrim.Surface.Elevator),"trim did not change elevator surface relative to neutral trim")

 local hydraulicNormal=baseState()
 hydraulicNormal.Controls.Aileron=1
 hydraulicNormal.Controls.Elevator=1
 FlightControls.new(hydraulicNormal):Step(0.1)
 local normalAileron=math.abs(hydraulicNormal.Surface.Aileron)
 local normalElevator=math.abs(hydraulicNormal.Surface.Elevator)
 local hydraulicDegraded=baseState()
 hydraulicDegraded.Controls.Aileron=1
 hydraulicDegraded.Controls.Elevator=1
 hydraulicDegraded.Hydraulic.A.Pressure=0
 hydraulicDegraded.Hydraulic.B.Pressure=0
 FlightControls.new(hydraulicDegraded):Step(0.1)
 check(hydraulicDegraded.HydraulicDemand.FlightControls>0,"hydraulic failure must not erase flight-control demand")
 check(math.abs(hydraulicDegraded.Surface.Aileron)<normalAileron,"hydraulic degradation must reduce aileron surface authority")
 check(math.abs(hydraulicDegraded.Surface.Elevator)<normalElevator,"hydraulic degradation must reduce elevator surface authority")
 local normalPhysics=baseState()
 normalPhysics.Controls.Aileron=1
 FlightControls.new(normalPhysics):Step(0.1)
 Physics.new(normalPhysics):Step(1/60)
 local degradedPhysics=baseState()
 degradedPhysics.Controls.Aileron=1
 degradedPhysics.Hydraulic.A.Pressure=0
 degradedPhysics.Hydraulic.B.Pressure=0
 FlightControls.new(degradedPhysics):Step(0.1)
 Physics.new(degradedPhysics):Step(1/60)
 check(math.abs(degradedPhysics.RollRate)<math.abs(normalPhysics.RollRate),"hydraulic degradation must reduce roll response in Physics")
 check((normalPhysics.ControlFeel.PhysicsRollAuthority or 0)>0.9,"Physics must expose effective roll control authority")
 check((normalPhysics.ControlFeel.PhysicsPitchAuthority or 0)>=0,"Physics must expose effective pitch control authority")
 check((normalPhysics.ControlFeel.PhysicsYawAuthority or 0)>=0,"Physics must expose effective yaw control authority")
 check((degradedPhysics.ControlFeel.PhysicsRollAuthority or 0)<(normalPhysics.ControlFeel.PhysicsRollAuthority or 0),"hydraulic degradation must propagate into Physics roll-authority telemetry")

 local yawState=baseState()
 yawState.Yaw=10
 yawState.Heading=10
 yawState.Surface.Rudder=1
 Physics.new(yawState):Step(1/60)
 check(math.abs(yawState.Yaw-10)>0.0001,"yaw attitude must integrate from yaw rate")
 check(math.abs(yawState.Yaw-yawState.YawRate)>0.0001,"yaw angle must not be overwritten with yaw rate")

 -- World velocity must use the same heading convention as WeatherPhysics.
 -- Heading 0 is +Z and heading 90 is +X in this simulator coordinate model.
 local forwardState=baseState()
 forwardState.Heading=0
 local z0=forwardState.Position.Z
 Physics.new(forwardState):Step(1/60)
 check(forwardState.Velocity.Z>0,"heading 0 must produce positive-Z air velocity")
 check(forwardState.Position.Z>z0,"heading 0 must advance Position toward +Z")

 local eastState=baseState()
 eastState.Heading=90
 local x0=eastState.Position.X
 Physics.new(eastState):Step(1/60)
 check(eastState.Velocity.X>0,"heading 90 must produce positive-X air velocity")
 check(eastState.Position.X>x0,"heading 90 must advance Position toward +X")

 -- Pitch must not be added to Velocity.Y on top of the independently
 -- integrated vertical speed; otherwise climb/descent is double-counted.
 local velocityState=baseState()
 velocityState.Pitch=10
 velocityState.VerticalSpeed=0
 Physics.new(velocityState):Step(1/60)
 local expectedVertical=velocityState.VerticalSpeed*(0.3048/60)
 check(math.abs(velocityState.Velocity.Y-expectedVertical)<1e-5,"Velocity.Y must match integrated vertical speed without pitch double-counting")
 return true
end
return {Run=run}
