-- AutoThrottle envelope regression tests
local AutoThrottle=require(script.Parent.Parent.AutoThrottle)
local function expect(condition,message) if not condition then error(message,2) end end
local function stateTemplate()
 return {
  IndicatedAirspeed=150,Airspeed=150,StallWarning=false,StallActive=false,OverspeedWarning=false,
  Throttle={[1]=0.4,[2]=0.4},Engines={{Running=true,N1=70,Thrust=18000},{Running=true,N1=70,Thrust=18000}},
  Autopilot={Enabled=true,TargetSpeed=150,GoAround=false},VNAV={Mode="OFF"},AutoThrottle={Enabled=true,Active=false,ThrottleCommand={[1]=0.4,[2]=0.4}},
 }
end
local function makeState(data)
 return {data=data,Get=function(self) return self.data end}
end
local function run()
 local s=stateTemplate(); s.StallActive=true
 local state=makeState(s); local at=AutoThrottle.new(state); at:Step(1/60)
 expect(s.AutoThrottle.Mode=="ENVELOPE_STALL","stall must inhibit autothrottle")
 expect(s.AutoThrottle.Protection=="STALL_ACTIVE","stall protection flag missing")
 expect(math.abs(s.Throttle[1]-0.4)<1e-6 and math.abs(s.Throttle[2]-0.4)<1e-6,"stall must not blindly command max thrust")
 s.StallActive=false; s.OverspeedWarning=true; s.Throttle={[1]=0.8,[2]=0.8}; s.AutoThrottle.ThrottleCommand={[1]=0.8,[2]=0.8}; at:Step(1/60)
 expect(s.AutoThrottle.Mode=="ENVELOPE_OVERSPEED","overspeed mode missing")
 expect(s.Throttle[1]<0.8 and s.Throttle[2]<0.8,"overspeed must reduce throttle")
 s.OverspeedWarning=false; s.Engines[1].Running=false; s.Engines[1].N1=0; s.Engines[1].Thrust=0; s.AutoThrottle.ThrottleCommand={[1]=0.8,[2]=0.8}; s.Throttle={[1]=0.8,[2]=0.8}; at:Step(1/60)
 expect(s.AutoThrottle.Mode=="SINGLE_ENGINE_SPEED","single engine mode missing")
 expect(s.Throttle[1]==0,"failed engine throttle must be zero")
 return true
end
return run()
