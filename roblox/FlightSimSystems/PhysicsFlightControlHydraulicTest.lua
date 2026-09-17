-- Regression contract for Physics.lua v2.7.
-- This test is intended to run inside Roblox Studio with the real State/Physics modules.
local Physics=require(script.Parent.Physics)

local function expect(name,condition)
 if not condition then error("PhysicsFlightControlHydraulicTest failed: "..name,2) end
end

local function makeState()
 local state={data={
  Airspeed=140,Altitude=5000,VerticalSpeed=0,Pitch=2,Roll=0,Heading=0,PitchRate=0,RollRate=0,YawRate=0,Yaw=0,Sideslip=0,Beta=0,GroundContact=false,
  Position=Vector3.zero,Velocity=Vector3.zero,Throttle={0,0},TrimPitch=0,
  Fuel={Total=20000},Engines={{Thrust=0},{Thrust=0}},Surface={Aileron=0.8,Elevator=0.8,Rudder=0.5,Flap=0},GearPosition={Nose=0,Left=0,Right=0},
  Hydraulic={A={Pressure=3000},B={Pressure=3000},Standby={Pressure=0}},ControlFeel={AileronHydraulic=1,ElevatorHydraulic=1,RudderHydraulic=1,ManualReversion=false},
  EngineIntegration={},Brakes={BrakePressure=0,LeftPressure=0,RightPressure=0},WeatherEffects={},Weather={}
 }}
 function state:Get() return self.data end
 return state
end

local state=makeState()
local physics=Physics.new(state)
physics:Step(1/60)
local normalRoll=math.abs(state.data.RollRate)
local normalPitch=math.abs(state.data.PitchRate)

state.data.Hydraulic.A.Pressure=0
state.data.Hydraulic.B.Pressure=0
state.data.Hydraulic.Standby.Pressure=3000
state.data.ControlFeel.AileronHydraulic=0.12
state.data.ControlFeel.ElevatorHydraulic=0.12
state.data.ControlFeel.RudderHydraulic=0.25
state.data.ControlFeel.ManualReversion=true
state.data.RollRate=0
state.data.PitchRate=0
physics:Step(1/60)

expect("normal hydraulic authority exists",normalRoll>0 or normalPitch>0)
expect("manual reversion does not restore full aileron authority",math.abs(state.data.RollRate)<normalRoll or normalRoll==0)
expect("manual reversion does not restore full elevator authority",math.abs(state.data.PitchRate)<normalPitch or normalPitch==0)

return true
