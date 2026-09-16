-- FlightSim physics ground/touchdown contract tests v0.1
-- Source-level tests; Roblox runtime execution is still required for engine integration.
local Physics=require(script.Parent.Physics)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Airspeed=0,Altitude=0,VerticalSpeed=0,Pitch=0,Roll=0,Heading=0,Position=Vector3.new(0,0,0),Velocity=Vector3.new(0,0,0),GroundContact=true,Throttle={0,0},Engines={{Thrust=0},{Thrust=0}},Fuel={Total=10000},Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Hydraulic={A=1800,B=1800},Brakes={BrakePressure=0,LeftPressure=0,RightPressure=0},GroundSteering={YawRate=0},WeatherEffects={EffectiveAirspeed=0,WindUKts=0,WindVKts=0}}
end
local function run()
 local s=state(base()); local p=Physics.new(s); p:Step(1/60)
 check(s.data.Altitude==0 and s.data.Position.Y==0,"ground state must remain at runway elevation")
 s.data.Engines[1].Thrust=60000; s.data.Engines[2].Thrust=60000; s.data.Throttle={1,1}; s.data.Airspeed=95; s.data.Surface.Elevator=1
 for _=1,30 do p:Step(1/60) end
 check(s.data.Airspeed>0,"thrust must produce forward acceleration")
 s.data.GroundContact=false; s.data.Altitude=1000; s.data.VerticalSpeed=-300; s.data.GearStatus={DownLocked=true}; s.data.Airspeed=130
 p:Step(1/60)
 check(s.data.VerticalSpeed<0,"descending state must retain negative vertical speed")
 s.data.Altitude=1; s.data.VerticalSpeed=-100; s.data.GroundContact=false; s.data.GearStatus={DownLocked=true}; p:Step(1/60)
 check(s.data.GroundContact and s.data.Altitude==0 and s.data.VerticalSpeed==0,"low-altitude descent with gear down must touchdown")
 return true
end
return {Run=run}
