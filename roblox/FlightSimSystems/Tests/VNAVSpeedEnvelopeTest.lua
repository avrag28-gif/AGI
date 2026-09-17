-- Regression tests for VNAV speed/envelope coupling.
local VNAV=require(script.Parent.Parent.VNAV)
local function assertTrue(v,msg) assert(v,msg) end
local function assertNear(a,b,t,msg) assert(math.abs(a-b)<=t,msg.." got="..tostring(a).." expected="..tostring(b)) end
local function makeState(data) local state={data=data}; function state:Get() return self.data end; return state end

-- A speed constraint below the calculated stall margin must be raised to a safe guidance target.
do
 local data={
  Altitude=5000,Airspeed=150,Navigation={Mode="LNAV",ActiveWaypoint=1,DistanceToWaypoint=10000,Route={{Position=Vector3.new(0,0,10000),Altitude=3000,Speed=80,SpeedConstraint="BELOW"}}},
  Autopilot={TargetAltitude=3000},FMC={},VNAV={Mode="VNAV"},FlightEnvelope={StallSpeedKt=120,StallMarginKt=20,Overspeed=false}
 }
 local v=VNAV.new(makeState(data)); v:Step(1/60)
 assertTrue(data.VNAV.TargetSpeed>=135,"VNAV must not command below stall margin")
 assertTrue(data.VNAV.GuidanceLimited==true,"speed protection must flag guidance limit")
end

-- Overspeed envelope must cap the selected speed at the 737-800 VMO bound.
do
 local data={
  Altitude=20000,Airspeed=300,Navigation={Mode="LNAV",ActiveWaypoint=1,DistanceToWaypoint=10000,Route={{Position=Vector3.new(0,0,10000),Altitude=21000,Speed=350,SpeedConstraint="AT"}}},
  Autopilot={TargetAltitude=21000},FMC={},VNAV={Mode="VNAV"},FlightEnvelope={StallSpeedKt=120,StallMarginKt=50,Overspeed=true}
 }
 local v=VNAV.new(makeState(data)); v:Step(1/60)
 assertNear(data.VNAV.TargetSpeed,340,1e-9,"VNAV must cap speed at VMO")
end

print("VNAVSpeedEnvelopeTest PASS")
return true
