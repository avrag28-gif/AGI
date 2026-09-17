-- FlightSim energy-management source tests v0.1
-- These tests are structural/unit checks only; Roblox Studio runtime execution is not performed here.
local Physics=require(script.Parent.Physics)
local function check(ok,msg) assert(ok,msg) end
local function makeState(overrides)
 local d={Airspeed=140,IndicatedAirspeed=140,Altitude=3000,Heading=90,Pitch=0,Roll=0,VerticalSpeed=0,GroundContact=false,PitchRate=0,RollRate=0,YawRate=0,Position=Vector3.new(0,914.4,0),Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Controls={Aileron=0,Elevator=0,Rudder=0,Flap=0,Trim=0},Hydraulic={A=3000,B=3000},Fuel={Total=10000},Engines={[1]={Running=true,Thrust=54000,N1=85},[2]={Running=true,Thrust=54000,N1=85}},Throttle={[1]=1,[2]=1},ReverseThrust=0,Brakes={BrakePressure=0,LeftPressure=0,RightPressure=0},GearPosition={Nose=0,Left=0,Right=0},GearStatus={DownLocked=false}}
 for k,v in pairs(overrides or {}) do d[k]=v end
 return {data=d,Get=function(self)return self.data end}
end
local function stepN(p,n,dt) for _=1,n do p:Step(dt) end end
local function run()
 local dt=1/60
 local climb=makeState({Pitch=10,Surface={Aileron=0,Elevator=0.5,Rudder=0,Flap=0}}); local pc=Physics.new(climb); local initialAlt=climb.data.Altitude; stepN(pc,120,dt); check(climb.data.Altitude>initialAlt,"positive pitch/elevator must produce climb")
 local idle=makeState({Airspeed=180,Throttle={[1]=0,[2]=0},Engines={[1]={Running=false,Thrust=0,N1=0},[2]={Running=false,Thrust=0,N1=0}}}); local pi=Physics.new(idle); stepN(pi,120,dt); check(idle.data.Airspeed<180,"idle thrust must reduce airspeed")
 local drag=makeState({Airspeed=180,Surface={Aileron=0,Elevator=0,Rudder=0,Flap=1},GearPosition={Nose=1,Left=1,Right=1},GearStatus={DownLocked=true},Throttle={[1]=0,[2]=0},Engines={[1]={Running=false,Thrust=0,N1=0},[2]={Running=false,Thrust=0,N1=0}}}); local pd=Physics.new(drag); stepN(pd,120,dt); check(drag.data.Airspeed<180,"flap and gear drag must reduce airspeed")
 local toga=makeState({Airspeed=130,Pitch=8,Surface={Aileron=0,Elevator=0.5,Rudder=0,Flap=0},Throttle={[1]=1,[2]=1}}); local pt=Physics.new(toga); stepN(pt,120,dt); check(toga.data.VerticalSpeed>0,"TOGA-like thrust plus pitch must climb")
 local one=makeState({Airspeed=145,Pitch=8,Surface={Aileron=0,Elevator=0.5,Rudder=0,Flap=0},Throttle={[1]=1,[2]=0},Engines={[1]={Running=true,Thrust=54000,N1=85},[2]={Running=false,Thrust=0,N1=0}}); local po=Physics.new(one); stepN(po,120,dt); check(one.data.EngineIntegration.EngineOut==true,"failed engine must be detected") ; check(math.abs(one.data.EngineIntegration.ThrustAsymmetry)>0.9,"engine-out must create strong thrust asymmetry")
 return true
end
return {Run=run}
