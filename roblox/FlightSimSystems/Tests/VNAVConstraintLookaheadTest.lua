-- VNAV downstream constraint lookahead regression tests.
local VNAV=require(script.Parent.Parent.VNAV)
local stateData={
 Altitude=20000,
 IndicatedAirspeed=250,
 FlightEnvelope={StallSpeedKt=110,Overspeed=false,StallMarginKt=40},
 Autopilot={TargetAltitude=20000,TargetSpeed=250},
 FMC={CruiseAltitude=20000},
 Navigation={
  ActiveWaypoint=1,
  DistanceToWaypoint=100000,
  Route={
   {Ident="A",Position=Vector3.new(0,0,0),Altitude=20000,AltitudeConstraint="AT",Speed=250,SpeedConstraint="AT"},
   {Ident="B",Position=Vector3.new(50000,0,0),Altitude=10000,AltitudeConstraint="BELOW",MaxAltitude=10000,Speed=220,SpeedConstraint="BELOW"},
   {Ident="C",Position=Vector3.new(100000,0,0),Altitude=5000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT"},
  },
 },
}
local State={}
function State:Get() return stateData end
local controller=VNAV.new(State)
stateData.VNAV={Mode="VNAV"}
controller:Step(1/60)
assert(stateData.VNAV.ConstraintLookaheadIndex==2,"expected downstream altitude constraint index 2")
assert(stateData.VNAV.NextConstraintAltitude==10000,"expected downstream altitude constraint altitude")
assert(stateData.VNAV.NextConstraintType=="BELOW","expected downstream BELOW constraint")
assert(stateData.VNAV.TopOfDescentDistance~=nil,"expected TOD lookahead")
assert(stateData.VNAV.TargetSpeed==250,"active-leg speed constraint must remain active before sequencing")
return true
