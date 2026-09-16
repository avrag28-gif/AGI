-- FlightSim VNAV waypoint-transition tests v0.3
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Altitude=20000,Airspeed=220,Autopilot={TargetAltitude=20000,TargetSpeed=220},Navigation={ActiveWaypoint=1,DistanceToWaypoint=60000,Route={
  {Ident="CLB",Position=Vector3.zero,Altitude=30000,AltitudeConstraint="AT",Speed=250,SpeedConstraint="AT"},
  {Ident="DES",Position=Vector3.new(60000,0,0),Altitude=12000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT"},
 }},FMC={CruiseAltitude=30000},VNAV={Mode="VNAV"}})
 local v=VNAV.new(s)
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"first waypoint altitude must drive VNAV")
 check(s.data.VNAV.TargetSpeed==250,"first waypoint speed must drive VNAV")
 check(s.data.VNAV.Phase=="CLIMB","first waypoint must produce climb phase")
 check(s.data.VNAV.TopOfDescentDistance==nil,"climb waypoint must not expose a descent TOD")
 s.data.Navigation.ActiveWaypoint=2
 s.data.Navigation.DistanceToWaypoint=60000
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==12000,"VNAV must switch immediately to the new waypoint altitude")
 check(s.data.VNAV.TargetSpeed==180,"VNAV must switch immediately to the new waypoint speed")
 check(s.data.VNAV.ConstraintAltitude==12000,"old altitude constraint must not remain active")
 check(s.data.VNAV.SpeedConstraintType=="AT","new speed constraint must replace old constraint")
 check(s.data.VNAV.Phase=="CRUISE","before TOD, VNAV should remain in cruise")
 check(s.data.VNAV.TopOfDescentDistance>0,"TOD distance must be positive before descent point")
 s.data.Navigation.DistanceToWaypoint=1000
 v:Step(1/60)
 check(s.data.VNAV.Phase=="DESCENT","VNAV must switch to descent after TOD")
 check(s.data.VNAV.TopOfDescentDistance==0,"TOD distance must clamp to zero after descent point")
 s.data.Navigation.ActiveWaypoint=3
 s.data.Autopilot.TargetSpeed=nil
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"missing waypoint altitude must fall back to FMC cruise altitude")
 check(s.data.VNAV.TargetSpeed==nil,"missing waypoint speed must clear stale speed constraint")
 check(s.data.VNAV.TopOfDescentDistance==nil,"missing waypoint must not retain stale TOD")
 return true
end
return {Run=run}
