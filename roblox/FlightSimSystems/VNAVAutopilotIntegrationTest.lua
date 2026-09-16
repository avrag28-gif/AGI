-- FlightSim VNAV -> Autopilot -> FlightControls integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local Autopilot=require(script.Parent.Autopilot)
local FlightControls=require(script.Parent.FlightControls)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Altitude=20000,Airspeed=220,IndicatedAirspeed=220,Heading=0,TrimPitch=0,GroundContact=false,
  Autopilot={Enabled=true,Mode="VNAV",TargetAltitude=20000,TargetHeading=0,TargetVerticalSpeed=0,TargetSpeed=220},
  Navigation={Mode="LNAV",ActiveWaypoint=1,DistanceToWaypoint=60000,Route={{Ident="DES",Position=Vector3.new(0,0,60000),Altitude=12000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT"}},CommandHeading=nil,CommandAltitude=nil,CommandVerticalSpeed=nil},
  FMC={CruiseAltitude=30000},VNAV={Mode="VNAV"},Controls={Aileron=0,Elevator=0,Rudder=0,Flap=0},
  Hydraulic={A=3000,B=3000},FailureEffects={},Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Engines={[1]={Running=true,N1=90},[2]={Running=true,N1=90}},Throttle={[1]=0,[2]=0}
 })
 local v=VNAV.new(s); local ap=Autopilot.new(s); local fc=FlightControls.new(s)
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==12000,"VNAV must publish active descent altitude")
 check(s.data.VNAV.TargetSpeed==180,"VNAV must publish active descent speed")
 check(s.data.VNAV.Phase=="CRUISE","VNAV must remain in cruise before TOD")
 check(s.data.VNAV.TopOfDescentDistance>0,"VNAV must publish positive TOD before descent")
 ap:Step(1/60)
 check(s.data.Autopilot.Mode=="VNAV","autopilot must remain in VNAV mode")
 check(s.data.Autopilot.CommandElevator<0,"VNAV descent command must request nose-down elevator")
 check(s.data.Autopilot.CommandAileron==0,"zero heading error must not create roll command")
 fc:Step(1/60)
 check(s.data.Surface.Elevator<0,"flight controls must consume VNAV autopilot elevator command")
 check(s.data.Surface.Aileron==0,"flight controls must preserve zero roll command")
 s.data.Navigation.DistanceToWaypoint=1000
 v:Step(1/60); ap:Step(1/60); fc:Step(1/60)
 check(s.data.VNAV.Phase=="DESCENT","VNAV must enter descent at/past TOD")
 check(s.data.Autopilot.CommandElevator<0,"autopilot must continue descent command after TOD")
 check(s.data.Surface.Elevator<0,"flight controls must continue applying descent command")
 return true
end
return {Run=run}
