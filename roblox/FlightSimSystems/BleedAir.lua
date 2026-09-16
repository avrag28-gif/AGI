-- FlightSim bleed-air / pack availability model v0.1
-- Game-simulation abstraction; not a certified pneumatic-system model.
local BleedAir={}; BleedAir.__index=BleedAir
local function clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or 0)) end
function BleedAir.new(state) return setmetatable({state=state},BleedAir) end
function BleedAir:Step(dt)
 local x=self.state:Get(); local b=x.BleedAir or {}; local e1=x.Engines and x.Engines[1] or {}; local e2=x.Engines and x.Engines[2] or {}; local apu=x.APU or {}; local el=x.Electrical or {}; local ef=x.Failures and x.Failures.Engines or {}; local pf=x.Failures and x.Failures.Pressurization or {}
 local n1=e1.N1 or 0; local n2=e2.N2 or 0
 b.Engine1Source=e1.Running==true and not (ef[1] and ef[1].Active) and pf.Pack1~=true
 b.Engine2Source=e2.Running==true and not (ef[2] and ef[2].Active) and pf.Pack2~=true
 b.APUAvailable=apu.Running==true and apu.GeneratorAvailable==true and (el.Bus1==true or el.Bus2==true)
 b.APUSource=b.APUAvailable and pf.Pack1~=true
 b.Pack1Available=b.Engine1Source or b.APUSource
 b.Pack2Available=b.Engine2Source or (b.APUAvailable and pf.Pack2~=true)
 b.Pack1Output=b.Pack1Available and clamp(math.max(n2/70,0.35),0,1) or 0
 b.Pack2Output=b.Pack2Available and clamp(math.max(n2/70,0.35),0,1) or 0
 b.TotalAirflow=clamp(b.Pack1Output+b.Pack2Output,0,2)
 b.SourceAvailable=b.Pack1Available or b.Pack2Available
 b.BleedPressure=clamp(b.TotalAirflow*42,0,84)
 x.BleedAir=b
 if x.Pressurization then
  x.Pressurization.Pack1Available=b.Pack1Available; x.Pressurization.Pack2Available=b.Pack2Available
  x.Pressurization.BleedSource1=b.Engine1Source or b.APUSource; x.Pressurization.BleedSource2=b.Engine2Source or (b.APUAvailable and pf.Pack2~=true)
  x.Pressurization.SourceAvailable=b.SourceAvailable
 end
end
return BleedAir
