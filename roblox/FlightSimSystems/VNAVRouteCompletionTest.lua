-- FlightSim VNAV route-completion regression tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Position=Vector3.new(0,0,0),Altitude=12000,Airspeed=210,IndicatedAirspeed=210,
  Navigation={Mode="LNAV",ActiveWaypoint=2,RouteComplete=true,Route={{Ident="FIX1",Position=Vector3.new(1000,0,0)},{Ident="DEST",Position=Vector3.new(2000,0,0)}},DistanceToWaypoint=0},
  FMC={CruiseAltitude=30000},Autopilot={TargetAltitude=12000,TargetSpeed=210},FlightEnvelope={StallMarginKt=80,Overspeed=false},
  VNAV={Mode="VNAV",Phase="DESCENT",TargetAltitude=30000,VerticalSpeed=-1500,CommandVerticalSpeed=-1500,ConstraintType="CRUISE",ConstraintAltitude=30000,TargetSpeed=210,TopOfDescentDistance=10000}
 })
 local v=VNAV.new(s)
 v:Step(1/60)
 local nav=s.data.Navigation
 local stateV=s.data.VNAV
 check(stateV.Phase=="COMPLETE","VNAV must enter COMPLETE after navigation route completion")
 check(stateV.CommandVerticalSpeed==nil,"completed VNAV must clear vertical-speed guidance")
 check(stateV.TargetAltitude==nil,"completed VNAV must clear altitude target")
 check(stateV.TargetSpeed==nil,"completed VNAV must clear speed target")
 check(nav.CommandAltitude==nil,"completed VNAV must clear navigation altitude command")
 check(nav.CommandVerticalSpeed==nil,"completed VNAV must clear navigation vertical-speed command")
 return true
end
return {Run=run}
