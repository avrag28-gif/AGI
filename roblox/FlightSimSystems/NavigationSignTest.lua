-- FlightSim navigation sign contract tests v0.1
-- Source-level tests for heading, bearing, cross-track and ILS localizer sign conventions.
local Navigation=require(script.Parent.Navigation)
local Approach=require(script.Parent.Approach)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Position=Vector3.new(-1000,0,0),Heading=0,Altitude=1000,Airspeed=140,Autopilot={TargetHeading=0,TargetAltitude=1000},Navigation={Mode="LNAV",Route={{Position=Vector3.new(0,0,0),CaptureRadius=250}},ActiveWaypoint=1,RouteComplete=false}})
 local nav=Navigation.new(s); nav:Step(1/60)
 check(s.data.Navigation.BearingToWaypoint==90,"bearing from west to north-oriented waypoint must be 90 degrees")
 check(s.data.Navigation.CrossTrackError<0,"left/west of an east-west? cross-track sign must be deterministic")
 local approach=Approach.new(s)
 check(approach:SetRunway({Position=Vector3.new(0,0,0),Heading=0,Elevation=0,GlideSlope=3,LocalizerLength=20000,ILSFrequency=110.3,ILSIdent="TEST"}),"valid runway rejected")
 s.data.Avionics={Radios=true}; s.data.Radios={NAV1=110.3}; s.data.Position=Vector3.new(-1000,0,-10000); s.data.Altitude=2000
 approach:Step(1/60)
 check(s.data.Navigation.ILS.Localizer>0,"aircraft left of runway centerline must produce positive localizer")
 s.data.Position=Vector3.new(1000,0,-10000); approach:Step(1/60)
 check(s.data.Navigation.ILS.Localizer<0,"aircraft right of runway centerline must produce negative localizer")
 return true
end
return {Run=run}
