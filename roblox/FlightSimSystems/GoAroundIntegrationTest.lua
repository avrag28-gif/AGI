-- FlightSim go-around integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local Autopilot=require(script.Parent.Autopilot)
local AutoThrottle=require(script.Parent.AutoThrottle)
local LandingModel=require(script.Parent.LandingModel)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Airspeed=135,IndicatedAirspeed=135,Altitude=1200,Heading=90,VerticalSpeed=-500,GroundContact=false,
  Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Controls={Aileron=0,Elevator=0,Rudder=0,Flap=0,Trim=0},Hydraulic={A=3000,B=3000},
  Engines={[1]={Running=true,N1=85,Thrust=50000},[2]={Running=true,N1=85,Thrust=50000}},Throttle={[1]=0.55,[2]=0.55},ReverseThrust=0,
  Navigation={Mode="APP",ILS={Available=true,LocalizerCaptured=true,GlideSlopeCaptured=true,LocalizerValid=true,GlideSlopeValid=true,GlideSlopeError=1},NAV1Receiver="ILS"},
  Autopilot={Enabled=true,TargetAltitude=1000,TargetHeading=90,TargetSpeed=135,Mode="APP_GS",GoAround=false,GoAroundHeading=nil,GoAroundAltitude=nil,CommandAileron=0,CommandElevator=0},
  AutoThrottle={Enabled=true,Active=true,TargetSpeed=135,SpeedError=0,ThrottleCommand={[1]=0.55,[2]=0.55},Mode="SPEED",Protection="NONE"},
  VNAV={Mode="VNAV",Phase="DESCENT",TargetAltitude=1000,TargetSpeed=135},Landing={Phase="FLARE",Flare=true,GoAround=false,Rollout=false}
 })
 local ap=Autopilot.new(s); local at=AutoThrottle.new(s); local landing=LandingModel.new(s)
 ap:Step(1/60)
 check(s.data.Autopilot.Mode=="APP_GS","approach should be in APP_GS before go-around")
 s.data.Autopilot.GoAround=true; s.data.Landing.GoAround=true; s.data.Autopilot.GoAroundHeading=90; s.data.Autopilot.GoAroundAltitude=2200
 at:GoAround(); ap:Step(1/60); at:Step(1/60); landing:Step(1/60)
 check(s.data.Autopilot.Enabled==true,"go-around must keep autopilot engaged")
 check(s.data.Autopilot.Mode=="GO_AROUND","autopilot must enter GO_AROUND mode")
 check(s.data.Navigation.Mode=="HDG","go-around must cancel approach navigation")
 check(s.data.VNAV.Mode=="OFF","go-around must cancel VNAV")
 check(s.data.Autopilot.CommandPitch>0,"go-around must command positive pitch")
 check(s.data.AutoThrottle.Active==true,"go-around must activate autothrottle")
 check(s.data.AutoThrottle.Mode=="TOGA","autothrottle must enter TOGA")
 check(s.data.Throttle[1]==1 and s.data.Throttle[2]==1,"healthy engines must receive full TOGA throttle")
 check(s.data.Landing.Phase=="GO_AROUND","landing state must expose GO_AROUND phase")
 s.data.Engines[2].Running=false; s.data.Engines[2].N1=0; at:Step(1/60)
 check(s.data.Throttle[1]==1 and s.data.Throttle[2]==0,"single-engine go-around must remove throttle from failed engine")
 s.data.GroundContact=true; s.data.Airspeed=70; landing:Step(1/60)
 check(s.data.Landing.Phase=="ROLLOUT","ground contact must take ownership over airborne go-around phase")
 return true
end
return {Run=run}
