-- FlightSim landing integration contract tests v0.1
-- Source-level tests for landing-state ownership, transition events and touchdown quality.
local LandingModel=require(script.Parent.LandingModel)
local LandingDynamics=require(script.Parent.LandingDynamics)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Airspeed=0,Altitude=0,VerticalSpeed=0,GroundContact=true,GearStatus={Nose=1,Left=1,Right=1,DownLocked=true},Landing={Phase="GROUND",Touchdown=false,Takeoff=false,Flare=false,Rollout=false,WheelContact=false,TouchdownQuality="NONE",TouchdownEvent=false,BrakingActive=false,ReverseThrust=false,RolloutDistance=0}}
end
local function run()
 local s=state(base()); local model=LandingModel.new(s); local dynamics=LandingDynamics.new(s)
 model:Step(1/60); dynamics:Step(1/60); check(not s.data.Landing.Takeoff,"initial ground state must not emit takeoff")
 s.data.GroundContact=false; s.data.Airspeed=100; s.data.Altitude=1000; s.data.VerticalSpeed=500
 model:Step(1/60); dynamics:Step(1/60); check(s.data.Landing.Takeoff,"ground-to-air transition must emit takeoff")
 model:Step(1/60); check(not s.data.Landing.Takeoff,"takeoff must be a one-tick transition event")
 s.data.Altitude=40; s.data.VerticalSpeed=-300; s.data.Airspeed=135; model:Step(1/60); check(s.data.Landing.Flare and s.data.Landing.Phase=="FLARE","eligible landing state must enter flare")
 s.data.GroundContact=true; s.data.VerticalSpeed=-100; dynamics:Step(1/60); check(s.data.Landing.Touchdown,"airborne-to-ground transition must emit touchdown")
 check(s.data.Landing.TouchdownEvent and s.data.Landing.TouchdownQuality=="SMOOTH","touchdown quality/event classification missing")
 check(s.data.Landing.WheelContact,"locked landing gear on ground must report wheel contact")
 check(s.data.Landing.Rollout,"moving aircraft on ground must enter rollout")
 check(s.data.Landing.RolloutDistance>0,"rollout distance must accumulate")
 s.data.GearStatus.DownLocked=false; dynamics:Step(1/60); check(not s.data.Landing.WheelContact,"wheel contact must require down-locked gear")
 return true
end
return {Run=run}
