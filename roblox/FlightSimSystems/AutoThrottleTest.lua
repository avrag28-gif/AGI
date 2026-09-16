-- FlightSim autothrottle contract tests v0.2
-- Deterministic state-level checks; not a Roblox runtime test runner.
local AutoThrottle=require(script.Parent.AutoThrottle)
local function assertEq(actual,expected,name) assert(actual==expected,string.format("%s: expected %s, got %s",name,tostring(expected),tostring(actual))) end
local function assertNear(actual,expected,tolerance,name) assert(math.abs(actual-expected)<=tolerance,string.format("%s: expected %.6f, got %.6f",name,expected,actual)) end
local function state()
 return {
  Autopilot={Enabled=true,TargetSpeed=250,GoAround=false},
  VNAV={Mode="OFF",TargetSpeed=nil},
  AutoThrottle={Enabled=false,Active=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF",Protection="NONE"},
  IndicatedAirspeed=200,
  Airspeed=200,
  Throttle={[1]=0.2,[2]=0.2},
  Engines={{Running=true,N1=40,StartFailed=false},{Running=true,N1=40,StartFailed=false}},
 }
end
local function makeState(s) return {Get=function() return s end} end
local function run()
 local s=state(); local at=AutoThrottle.new(makeState(s)); at:Step(1); assertEq(s.AutoThrottle.Enabled,false,"disabled preserves arm state"); assertNear(s.Throttle[1],0.2,1e-9,"disabled throttle left"); assertNear(s.Throttle[2],0.2,1e-9,"disabled throttle right")
 at:SetEnabled(true); at:Step(0.1); assertEq(s.AutoThrottle.Enabled,true,"enabled"); assertEq(s.AutoThrottle.Active,true,"active"); assertEq(s.AutoThrottle.TargetSpeed,250,"selected target speed"); assert(s.AutoThrottle.ThrottleCommand[1]>0.2,"closed loop raises thrust when slow"); assert(s.AutoThrottle.ThrottleCommand[1]<=0.535,"slew upper bound")
 s.IndicatedAirspeed=250; s.Airspeed=250; local before=s.AutoThrottle.ThrottleCommand[1]; at:Step(0.1); assert(s.AutoThrottle.ThrottleCommand[1]<before,"throttle reduces when at target")
 s.VNAV.Mode="VNAV"; s.VNAV.TargetSpeed=300; at:Step(0.1); assertEq(s.AutoThrottle.TargetSpeed,300,"VNAV target speed"); assertEq(s.AutoThrottle.Mode,"VNAV_SPEED","VNAV mode")
 s.IndicatedAirspeed=0; s.Airspeed=0; s.Engines[1].Running=false; s.Engines[1].N1=0; s.Engines[1].StartFailed=true; at:Step(0.1); assert(s.AutoThrottle.ThrottleCommand[1]==0,"failed engine command zero"); assert(s.AutoThrottle.ThrottleCommand[2]>0,"available engine command positive")
 s.Engines[2].Running=false; s.Engines[2].N1=0; s.Engines[2].StartFailed=true; at:Step(0.1); assertEq(s.AutoThrottle.Enabled,false,"no engine disarms")
 s.Autopilot.Enabled=false; s.AutoThrottle.Enabled=true; at:Step(0.1); assertEq(s.AutoThrottle.Enabled,false,"AP off disarms")
 s=state(); at=AutoThrottle.new(makeState(s)); s.IndicatedAirspeed=145; s.Airspeed=145; assert(at:GoAround(),"TOGA request accepted"); assertEq(s.AutoThrottle.Mode,"TOGA","TOGA mode"); assertEq(s.AutoThrottle.Protection,"TOGA","TOGA protection"); assertEq(s.AutoThrottle.Active,true,"TOGA active"); assertEq(s.AutoThrottle.TargetSpeed,165,"TOGA target speed"); assertEq(s.Throttle[1],1,"TOGA left thrust"); assertEq(s.Throttle[2],1,"TOGA right thrust")
 s.Engines[2].Running=false; s.Engines[2].N1=0; s.Engines[2].StartFailed=true; s.Autopilot.GoAround=true; at:Step(0.1); assertEq(s.Throttle[1],1,"TOGA single-engine left thrust"); assertEq(s.Throttle[2],0,"TOGA failed-engine right thrust")
 return true
end
return {Run=run}
