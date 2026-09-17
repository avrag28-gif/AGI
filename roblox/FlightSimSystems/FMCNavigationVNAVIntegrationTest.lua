-- FlightSim FMC -> Navigation -> VNAV integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local FMC=require(script.Parent.FMC)
local Navigation=require(script.Parent.Navigation)
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local route={
  {Ident="CLB1",Position=Vector3.new(0,0,0),Altitude=30000,AltitudeConstraint="AT",Speed=250,SpeedConstraint="AT",CaptureRadius=2500},
  {Ident="DES1",Position=Vector3.new(100000,0,0),Altitude=12000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT",CaptureRadius=2500},
 }
 local s=state({
  Position=Vector3.new(-50000,0,0),Altitude=20000,Airspeed=220,IndicatedAirspeed=220,Heading=90,
  Autopilot={Enabled=true,Mode="VNAV",TargetAltitude=20000,TargetHeading=90,TargetVerticalSpeed=0,TargetSpeed=220},
  Navigation={Mode="LNAV",ActiveWaypoint=1,Route={},RouteComplete=true,DistanceToWaypoint=0,BearingToWaypoint=0,CrossTrackError=0},
  FMC={Page="IDENT",Scratchpad="",CruiseAltitude=nil,Route={},Active=false},VNAV={Mode="VNAV"}
 })
 local f=FMC.new(s); local n=Navigation.new(s); local v=VNAV.new(s)
 check(f:SetRoute("WIII","WADD",route,30000)==true,"FMC must accept a valid route")
 check(#s.data.FMC.Route==2,"FMC must retain the cleaned route")
 check(#s.data.Navigation.Route==2,"FMC must publish the route to navigation")
 check(s.data.Navigation.ActiveWaypoint==1,"FMC must reset the active waypoint")
 n:Step(1/60)
 check(s.data.Navigation.DistanceToWaypoint>0,"navigation must calculate distance to the active waypoint")
 check(s.data.Navigation.BearingToWaypoint==90,"navigation must calculate the route bearing")
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"VNAV must consume the FMC route altitude through Navigation")
 check(s.data.VNAV.TargetSpeed==250,"VNAV must consume the FMC route speed through Navigation")
 check(s.data.VNAV.ConstraintType=="AT","VNAV must consume the FMC altitude constraint")
 check(s.data.VNAV.SpeedConstraintType=="AT","VNAV must consume the FMC speed constraint")
 check(s.data.VNAV.Phase=="CLIMB","the first higher constraint must produce climb guidance")
 s.data.Navigation.ActiveWaypoint=2
 n:Step(1/60)
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==12000,"VNAV must follow Navigation waypoint transitions")
 check(s.data.VNAV.TargetSpeed==180,"VNAV must follow the new waypoint speed")
 check(s.data.VNAV.Phase=="CRUISE","VNAV must remain in cruise before the descent TOD")
 check(s.data.VNAV.TopOfDescentDistance>0,"VNAV must publish a positive TOD before descent")
 return true
end
return {Run=run}
