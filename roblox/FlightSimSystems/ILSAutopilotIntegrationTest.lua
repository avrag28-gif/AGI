-- FlightSim ILS -> Autopilot integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local Approach=require(script.Parent.Approach)
local Autopilot=require(script.Parent.Autopilot)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local runway={Position=Vector3.zero,Heading=0,Elevation=500,GlideSlope=3,LocalizerLength=20000,ILSFrequency=110.3,ILSIdent="IABC"}
 local s=state({
  Position=Vector3.new(-1000,0,-10000),Altitude=2200,Airspeed=140,Heading=0,
  Electrical={Bus1=true,Bus2=true},Avionics={Radios=true},Radios={NAV1=110.3},
  Navigation={Mode="APP",ApproachRunway=nil,NAV1Receiver="ILS",ILS=nil,CommandHeading=0,CommandAltitude=nil},
  Autopilot={Enabled=true,Mode="APP",TargetHeading=0,TargetAltitude=2200,CommandAileron=0,CommandElevator=0},
  VNAV={Mode="OFF"}
 })
 local approach=Approach.new(s); local ap=Autopilot.new(s)
 check(approach:SetRunway(runway)==true,"approach must accept the runway")
 approach:Step(1/60)
 check(s.data.Navigation.ILS.Localizer>0,"aircraft left of centerline must produce positive localizer")
 s.data.Navigation.NAV1Receiver="ILS"
 s.data.Autopilot.CommandAileron=0
 ap:Step(1/60)
 check(s.data.Autopilot.Mode=="APP_ARMED" or s.data.Autopilot.Mode=="APP_LOC" or s.data.Autopilot.Mode=="APP_GS","autopilot must enter an APP mode with valid ILS")
 check(s.data.Autopilot.CommandAileron>0,"positive localizer must command a positive/right roll correction")
 s.data.Position=Vector3.new(1000,0,-10000)
 approach:Step(1/60); ap:Step(1/60)
 check(s.data.Navigation.ILS.Localizer<0,"aircraft right of centerline must produce negative localizer")
 check(s.data.Autopilot.CommandAileron<0,"negative localizer must command a negative/left roll correction")
 s.data.Position=Vector3.new(0,3500/3.28084,-10000)
 s.data.Altitude=3500
 approach:Step(1/60)
 ap:Step(1/60)
 check(s.data.Navigation.ILS.GlideSlopeError>0,"aircraft above glide slope must produce positive glide-slope error")
 check(s.data.Autopilot.Mode=="APP_GS" or s.data.Autopilot.Mode=="APP_LOC" or s.data.Autopilot.Mode=="APP_ARMED","autopilot must remain in APP guidance")
 check(s.data.Autopilot.CommandElevator<=0,"aircraft above glide slope must command pitch-down correction")
 return true
end
return {Run=run}
