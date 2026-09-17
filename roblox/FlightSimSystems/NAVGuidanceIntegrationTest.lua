-- FlightSim NAV receiver -> VOR/ILS guidance integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local Approach=require(script.Parent.Approach)
local VOR=require(script.Parent.VOR)
local NAVReceiver=require(script.Parent.NAVReceiver)
local Navigation=require(script.Parent.Navigation)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local runway={Position=Vector3.zero,Heading=0,Elevation=500,GlideSlope=3,LocalizerLength=20000,ILSFrequency=110.3,ILSIdent="IABC"}
 local s=state({
  Position=Vector3.new(-10000,0,1000),Altitude=2200,Airspeed=180,Heading=0,
  Electrical={Bus1=true,Bus2=true},Avionics={Radios=true},Radios={NAV1=110.3,NAV2=113.0},
  Navigation={Mode="APP",ActiveWaypoint=1,Route={},RouteComplete=false,DistanceToWaypoint=0,BearingToWaypoint=0,CrossTrackError=0,ApproachRunway=nil,ILS=nil,VOR=nil,VOR2=nil,VORStation=nil,VORStationNAV2=nil,NAV1Receiver="NONE",NAV1Signal=nil,NAV2Receiver="NONE",NAV2Signal=nil,VORCourse=0,VORCourseNAV2=0},
  Autopilot={TargetHeading=0,TargetAltitude=2200},FMC={CruiseAltitude=30000}
 })
 local approach=Approach.new(s); local vor=VOR.new(s); local receiver=NAVReceiver.new(s); local nav=Navigation.new(s)
 check(approach:SetRunway(runway)==true,"approach must accept the ILS runway")
 approach:Step(1/60); receiver:Step(1/60); nav:Step(1/60)
 check(s.data.Navigation.NAV1Receiver=="ILS","APP mode must select the tuned ILS on NAV1")
 check(s.data.Navigation.NAV1Frequency==110.3,"NAV1 must retain the tuned ILS frequency")
 check(s.data.Navigation.NAV1Signal~=nil,"NAV1 must expose the selected ILS signal")
 check(s.data.Navigation.CommandHeading~=nil,"APP guidance must publish a heading command")
 check(s.data.Navigation.CommandAltitude~=nil,"valid ILS glide-slope geometry must publish an altitude command")
 s.data.Navigation.Mode="VOR"
 s.data.Navigation.ApproachRunway=nil
 check(vor:SetStation({Position=Vector3.new(0,0,20000),Frequency=113.0,Ident="VOR1",DME=true},"NAV1")==true,"VOR station must be accepted")
 check(vor:SetCourse(0,"NAV1")==true,"VOR course must be accepted")
 vor:Step(1/60); receiver:Step(1/60); nav:Step(1/60)
 check(s.data.Navigation.NAV1Receiver=="VOR","VOR mode must select the tuned VOR on NAV1")
 check(s.data.Navigation.NAV1Ident=="VOR1","NAV1 must expose the VOR ident")
 check(s.data.Navigation.NAV1Signal~=nil,"NAV1 must expose the selected VOR signal")
 check(s.data.Navigation.NAV1Signal.DMEAvailable==true,"VOR DME capability must propagate to the receiver signal")
 check(s.data.Navigation.CommandHeading~=nil,"VOR guidance must publish a heading command")
 s.data.Avionics.Radios=false
 receiver:Step(1/60)
 check(s.data.Navigation.NAV1Receiver=="NONE","receiver must clear NAV1 when radios lose power")
 check(s.data.Navigation.NAV1Signal==nil,"receiver must clear stale NAV1 signal when radios lose power")
 return true
end
return {Run=run}
