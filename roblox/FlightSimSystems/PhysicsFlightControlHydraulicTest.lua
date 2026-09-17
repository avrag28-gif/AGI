-- Regression contract for Physics.lua v2.8.
-- Physics consumes achieved surface authority; FlightControls owns hydraulic limiting.
local Physics=require(script.Parent.Physics)

local function expect(name,condition)
 if not condition then error("PhysicsFlightControlHydraulicTest failed: "..name,2) end
end

local function makeState()
 local state={data={
  Airspeed=140,Altitude=5000,VerticalSpeed=0,Pitch=2,Roll=0,Heading=0,PitchRate=0,RollRate=0,YawRate=0,Yaw=0,Sideslip=0,Beta=0,GroundContact=false,
  Position=Vector3.zero,Velocity=Vector3.zero,Throttle={0,0},TrimPitch=0,
  Fuel={Total=20000},Engines={{Thrust=0},{Thrust=0}},Surface={Aileron=0.8,Elevator=0.8,Rudder=0.5,Flap=0},GearPosition={Nose=0,Left=0,Right=0},
  Hydraulic={A={Pressure=3000},B={Pressure=3000},Standby={Pressure=0}},ControlFeel={},
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

-- Simulate FlightControls after both primary systems are lost and manual reversion
-- limits the achieved surface deflection before Physics consumes it.
state.data.Hydraulic.A.Pressure=0
state.data.Hydraulic.B.Pressure=0
state.data.Hydraulic.Standby.Pressure=3000
state.data.Surface.Aileron=0.096
state.data.Surface.Elevator=0.096
state.data.Surface.Rudder=0.125
state.data.RollRate=0
state.data.PitchRate=0
physics:Step(1/60)

expect("normal control response exists",normalRoll>0 or normalPitch>0)
expect("reduced achieved aileron authority produces reduced roll response",math.abs(state.data.RollRate)<normalRoll or normalRoll==0)
expect("reduced achieved elevator authority produces reduced pitch response",math.abs(state.data.PitchRate)<normalPitch or normalPitch==0)

return true
