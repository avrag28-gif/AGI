-- FlightSim navigation/FMC progress tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local Navigation=require(script.Parent.Navigation)
local FMC=require(script.Parent.FMC)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Position=Vector3.new(-1000,0,5000),Heading=0,Altitude=10000,Airspeed=220,Autopilot={TargetHeading=0,TargetAltitude=10000},Navigation={Mode="LNAV",Route={},ActiveWaypoint=1,RouteComplete=false},FMC={}})
 local nav=Navigation.new(s); local fmc=FMC.new(s)
 local route={{Ident="WP1",Position=Vector3.new(0,0,10000),CaptureRadius=1000},{Ident="WP2",Position=Vector3.new(10000,0,10000),CaptureRadius=1000}}
 check(fmc:SetRoute("TEST","DEST",route,30000),"FMC route must be accepted")
 nav:Step(1/60); fmc:Step(1/60)
 check(s.data.Navigation.ActiveWaypoint==1,"first waypoint must remain active outside capture")
 check(s.data.Navigation.CrossTrackError>0,"left-of-track position must produce positive cross-track error")
 check(s.data.Navigation.CommandHeading>0 and s.data.Navigation.CommandHeading<90,"LNAV must correct toward the track")
 s.data.Position=Vector3.new(0,0,10000); nav:Step(1/60); fmc:Step(1/60)
 check(s.data.Navigation.ActiveWaypoint==2,"first capture must advance to second waypoint")
 check(s.data.FMC.ActiveWaypoint==2,"FMC progress must mirror navigation")
 check(s.data.FMC.RouteComplete==false,"route must not complete before final waypoint")
 s.data.Position=Vector3.new(10000,0,10000); nav:Step(1/60); fmc:Step(1/60)
 check(s.data.Navigation.RouteComplete==true,"final capture must complete navigation route")
 check(s.data.FMC.RouteComplete==true and s.data.FMC.Active==false,"FMC must become inactive after route completion")
 return true
end
return {Run=run}
