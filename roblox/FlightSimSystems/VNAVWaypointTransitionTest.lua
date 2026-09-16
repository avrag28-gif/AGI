-- FlightSim VNAV waypoint-transition tests v0.5
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Altitude=30000,Airspeed=220,Autopilot={TargetAltitude=30000,TargetSpeed=220},Navigation={ActiveWaypoint=1,DistanceToWaypoint=200000,Route={
  {Ident="CRZ1",Position=Vector3.zero,Altitude=30000,AltitudeConstraint="AT",Speed=250,SpeedConstraint="AT"},
  {Ident="CRZ2",Position=Vector3.new(200000,0,0),Altitude=30000,AltitudeConstraint="AT",Speed=230,SpeedConstraint="AT"},
  {Ident="DES",Position=Vector3.new(400000,0,0),Altitude=12000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT"},
 }},FMC={CruiseAltitude=30000},VNAV={Mode="VNAV"}})
 local v=VNAV.new(s)
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"first waypoint altitude must drive VNAV")
 check(s.data.VNAV.TargetSpeed==250,"first waypoint speed must drive VNAV")
 check(s.data.VNAV.Phase=="ALTITUDE_CAPTURE","at the selected cruise altitude VNAV should hold altitude")
 check(s.data.VNAV.TopOfDescentDistance>0,"VNAV should look ahead to the downstream descent constraint")
 s.data.Navigation.ActiveWaypoint=2
 s.data.Navigation.DistanceToWaypoint=200000
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"same-altitude waypoint must retain the active altitude target")
 check(s.data.VNAV.TargetSpeed==230,"VNAV must switch immediately to the new waypoint speed")
 check(s.data.VNAV.Phase=="ALTITUDE_CAPTURE","same-altitude waypoint must not create a false descent phase")
 check(s.data.VNAV.TopOfDescentDistance>0,"downstream TOD must remain available after waypoint transition")
 s.data.Navigation.ActiveWaypoint=3
 s.data.Navigation.DistanceToWaypoint=200000
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==12000,"VNAV must switch immediately to the lower altitude constraint")
 check(s.data.VNAV.TargetSpeed==180,"VNAV must switch immediately to the lower waypoint speed")
 check(s.data.VNAV.Phase=="CRUISE","before the active lower constraint TOD, VNAV should remain in cruise")
 check(s.data.VNAV.TopOfDescentDistance>0,"active lower constraint must expose a positive TOD distance")
 s.data.Navigation.DistanceToWaypoint=1000
 v:Step(1/60)
 check(s.data.VNAV.Phase=="DESCENT","VNAV must switch to descent after TOD")
 check(s.data.VNAV.TopOfDescentDistance==0,"TOD distance must clamp to zero at the descent point")
 s.data.Navigation.ActiveWaypoint=4
 s.data.Autopilot.TargetSpeed=nil
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"missing waypoint altitude must fall back to FMC cruise altitude")
 check(s.data.VNAV.TargetSpeed==nil,"missing waypoint speed must clear stale speed constraint")
 check(s.data.VNAV.TopOfDescentDistance==nil,"missing waypoint must not retain stale TOD")
 return true
end
return {Run=run}
