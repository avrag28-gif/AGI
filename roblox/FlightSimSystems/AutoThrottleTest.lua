-- FlightSim autothrottle contract tests v0.1
-- Deterministic state-level checks; not a Roblox runtime test runner.
local AutoThrottle=require(script.Parent.AutoThrottle)
local function assertEq(actual,expected,name) assert(actual==expected,string.format("%s: expected %s, got %s",name,tostring(expected),tostring(actual))) end
local function assertNear(actual,expected,tolerance,name) assert(math.abs(actual-expected)<=tolerance,string.format("%s: expected %.6f, got %.6f",name,expected,actual)) end
local function state()
 return {
  Autopilot={Enabled=true,TargetSpeed=250},
  VNAV={Mode="OFF",TargetSpeed=nil},
  AutoThrottle={Enabled=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF"},
  IndicatedAirspeed=200,
  Airspeed=200,
  Throttle={[1]=0.2,[2]=0.2},
  Engines={{Running=true,N1=40,StartFailed=false},{Running=true,N1=40,StartFailed=false}},
 }
end
local function makeState(s) return {Get=function() return s end} end
local function run()
 local s=state(); local at=AutoThrottle.new(makeState(s)); at:Step(1); assertEq(s.AutoThrottle.Enabled,false,"disabled preserves arm state"); assertNear(s.Throttle[1],0.2,1e-9,"disabled throttle left"); assertNear(s.Throttle[2],0.2,1e-9,"disabled throttle right")
 at:SetEnabled(true); at:Step(0.1); assertEq(s.AutoThrottle.Enabled,true,"enabled"); assert(s.AutoThrottle.TargetSpeed==250,"selected target speed"); assert(s.AutoThrottle.ThrottleCommand[1]>0.2,"closed loop raises thrust when slow"); assert(s.AutoThrottle.ThrottleCommand[1]<=0.535,"slew upper bound")
 s.IndicatedAirspeed=250; s.Airspeed=250; local before=s.AutoThrottle.ThrottleCommand[1]; at:Step(0.1); assert(s.AutoThrottle.ThrottleCommand[1]<before,"throttle reduces when at target")
 s.VNAV.Mode="VNAV"; s.VNAV.TargetSpeed=300; at:Step(0.1); assertEq(s.AutoThrottle.TargetSpeed,300,"VNAV target speed")
 s.IndicatedAirspeed=0; s.Airspeed=0; s.Engines[1].Running=false; s.Engines[1].N1=0; s.Engines[1].StartFailed=true; at:Step(0.1); assert(s.AutoThrottle.ThrottleCommand[1]==0,"failed engine command zero"); assert(s.AutoThrottle.ThrottleCommand[2]>0,"available engine command positive")
 s.Engines[2].Running=false; s.Engines[2].N1=0; s.Engines[2].StartFailed=true; at:Step(0.1); assertEq(s.AutoThrottle.Enabled,false,"no engine disarms")
 s.Autopilot.Enabled=false; s.AutoThrottle.Enabled=true; at:Step(0.1); assertEq(s.AutoThrottle.Enabled,false,"AP off disarms")
 return true
end
return {Run=run}
