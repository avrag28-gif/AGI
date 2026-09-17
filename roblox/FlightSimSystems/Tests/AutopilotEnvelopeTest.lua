-- Regression tests for Autopilot v1.6 physical-envelope coupling.
local Autopilot=require(script.Parent.Parent.Autopilot)
local function assertTrue(v,msg) assert(v,msg) end
local function assertNear(a,b,t,msg) assert(math.abs(a-b)<=t,msg.." got="..tostring(a).." expected="..tostring(b)) end

local function makeState(data)
 local state={data=data}
 function state:Get() return self.data end
 return state
end

-- Stall-active must disconnect altitude-hold rather than commanding more pitch.
do
 local data={
  Airspeed=110,Altitude=10000,Heading=90,StallActive=true,
  FlightEnvelope={StallActive=true},
  Autopilot={Enabled=true,TargetAltitude=12000},
  Navigation={},VNAV={},Controls={},ControlFeel={AileronAuthority=1,ElevatorAuthority=1,RudderAuthority=1,HydraulicAuthority=1800},
 }
 local ap=Autopilot.new(makeState(data)); ap:Step(1/60)
 assertTrue(data.Autopilot.Enabled==false,"stall must disconnect autopilot")
 assertTrue(data.Autopilot.DisconnectReason=="STALL_ACTIVE","disconnect reason must identify stall")
 assertNear(data.Autopilot.CommandElevator,0,1e-9,"stall disconnect must zero elevator command")
end

-- With reduced control authority, AFDS command magnitude must be physically limited.
do
 local data={
  Airspeed=180,Altitude=10000,Heading=90,StallActive=false,
  FlightEnvelope={StallActive=false},
  Autopilot={Enabled=true,TargetAltitude=12000,TargetHeading=180},
  Navigation={Mode="ALT_HOLD"},VNAV={},Controls={},ControlFeel={AileronAuthority=0.35,ElevatorAuthority=0.35,RudderAuthority=0.35,HydraulicAuthority=600},
 }
 local ap=Autopilot.new(makeState(data)); ap:Step(1/60)
 assertTrue(math.abs(data.Autopilot.CommandElevator)<=0.35+1e-6,"elevator command must respect authority")
 assertTrue(data.Autopilot.AuthorityLimited==true,"limited authority flag must be set")
end

print("AutopilotEnvelopeTest PASS")
return true
