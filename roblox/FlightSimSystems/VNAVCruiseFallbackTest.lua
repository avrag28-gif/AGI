-- FlightSim VNAV cruise fallback regression tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Position=Vector3.new(0,0,0),Altitude=18000,Airspeed=240,IndicatedAirspeed=240,
  Navigation={Mode="LNAV",ActiveWaypoint=1,Route={{Ident="FIX1",Position=Vector3.new(100000,0,0)}},DistanceToWaypoint=100000},
  FMC={CruiseAltitude=30000},Autopilot={TargetAltitude=18000,TargetSpeed=240},FlightEnvelope={StallMarginKt=80,Overspeed=false},
  VNAV={Mode="VNAV"}
 })
 local v=VNAV.new(s)
 v:Step(1/60)
 check(s.data.VNAV.TargetAltitude==30000,"VNAV must use cruise altitude when the active waypoint has no altitude constraint")
 check(s.data.VNAV.ConstraintType=="CRUISE","cruise fallback must not masquerade as an AT waypoint constraint")
 check(s.data.VNAV.Phase=="CLIMB","cruise fallback above aircraft altitude must produce climb guidance")
 check(s.data.VNAV.ConstraintLookaheadIndex==nil,"cruise altitude must not become a downstream waypoint constraint")
 s.data.Navigation.Route={
  {Ident="FIX1",Position=Vector3.new(0,0,0)},
  {Ident="DESC",Position=Vector3.new(100000,0,0),Altitude=12000,AltitudeConstraint="AT"}
 }
 s.data.Navigation.ActiveWaypoint=1
 s.data.Navigation.DistanceToWaypoint=100000
 s.data.Altitude=20000
 v:Step(1/60)
 check(s.data.VNAV.ConstraintLookaheadIndex==2,"VNAV must detect an explicit downstream altitude constraint")
 check(s.data.VNAV.NextConstraintAltitude==12000,"VNAV must expose the downstream constrained altitude")
 check(s.data.VNAV.NextConstraintType=="AT","VNAV must preserve the downstream constraint type")
 return true
end
return {Run=run}
