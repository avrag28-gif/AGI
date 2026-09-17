-- FlightSim go-around flight-path coupling test v0.1
-- Source-level deterministic test; not Roblox Studio runtime execution.
local FlightControls=require(script.Parent.FlightControls)
local Physics=require(script.Parent.Physics)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Airspeed=135,Altitude=3000,Heading=90,Pitch=0,Roll=0,Yaw=0,YawRate=0,RollRate=0,PitchRate=0,VerticalSpeed=-500,GroundContact=false,Position=Vector3.zero,
  Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Controls={Aileron=0,Elevator=0,Rudder=0,Flap=0,Trim=0},Hydraulic={A=3000,B=3000},
  Engines={[1]={Running=true,Thrust=50000,N1=85},[2]={Running=true,Thrust=50000,N1=85}},Throttle={[1]=1,[2]=1},ReverseThrust=0,Brakes={BrakePressure=0,LeftPressure=0,RightPressure=0},GearPosition={Nose=1,Left=1,Right=1},GearStatus={DownLocked=true},WeatherEffects={},GroundSteering={YawRate=0},EngineIntegration={TotalThrust=0,ThrustAsymmetry=0,EngineOut=false,YawMoment=0}})
 s.data.Autopilot={Enabled=true,CommandAileron=0,CommandElevator=0,GoAround=true,Mode="GO_AROUND"}
 local fc=FlightControls.new(s); fc:Step(1/60)
 check(s.data.Surface.Elevator>0,"enabled go-around AP must propagate positive elevator command to the elevator surface")
 local p0=s.data.Pitch; local v0=s.data.VerticalSpeed
 local physics=Physics.new(s)
 for _=1,120 do physics:Step(1/60) end
 check(s.data.Pitch>p0,"positive elevator command must increase aircraft pitch")
 check(s.data.VerticalSpeed>v0,"go-around pitch must reverse the initial descent trend")
 check(s.data.Altitude>3000,"go-around climb must increase altitude in the flight model")
 return true
end
return {Run=run}
