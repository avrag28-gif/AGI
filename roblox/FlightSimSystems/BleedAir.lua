-- FlightSim bleed-air / pack availability model v0.4
-- Game-simulation abstraction; not a certified pneumatic-system model.
-- Engine bleed is gated by engine running state and usable N2 so a newly lit
-- engine cannot provide full pneumatic source before it has spooled.
local BleedAir={}; BleedAir.__index=BleedAir
local function clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or 0)) end
function BleedAir.new(state) return setmetatable({state=state},BleedAir) end
function BleedAir:Step(dt)
 local x=self.state:Get(); local b=x.BleedAir or {}; local e1=x.Engines and x.Engines[1] or {}; local e2=x.Engines and x.Engines[2] or {}; local apu=x.APU or {}; local failures=x.Failures or {}; local ef=failures.Engines or {}; local pf=failures.Pressurization or {}
 local n2_1=clamp((tonumber(e1.N2) or 0)/70,0,1); local n2_2=clamp((tonumber(e2.N2) or 0)/70,0,1); local apuOutput=clamp((tonumber(apu.RPM) or 0)/95,0,1)
 local engine1Failed=(ef[1] and ef[1].Active)==true; local engine2Failed=(ef[2] and ef[2].Active)==true
 local pack1Failed=pf.Pack1==true; local pack2Failed=pf.Pack2==true
 b.Engine1Source=e1.Running==true and not engine1Failed and (tonumber(e1.N2) or 0)>=50
 b.Engine2Source=e2.Running==true and not engine2Failed and (tonumber(e2.N2) or 0)>=50
 b.APUAvailable=apu.Running==true and apuOutput>0.15
 b.APUSource=b.APUAvailable
 b.Pack1Available=not pack1Failed and (b.Engine1Source or b.APUSource)
 b.Pack2Available=not pack2Failed and (b.Engine2Source or b.APUSource)
 b.Pack1Output=pack1Failed and 0 or clamp((b.Engine1Source and n2_1 or 0)+(b.APUSource and apuOutput or 0),0,1)
 b.Pack2Output=pack2Failed and 0 or clamp((b.Engine2Source and n2_2 or 0)+(b.APUSource and apuOutput or 0),0,1)
 b.TotalAirflow=clamp(b.Pack1Output+b.Pack2Output,0,2); b.SourceAvailable=b.Pack1Available or b.Pack2Available; b.BleedPressure=clamp(b.TotalAirflow*42,0,84)
 x.BleedAir=b
 if x.Pressurization then
  x.Pressurization.Pack1Available=b.Pack1Available; x.Pressurization.Pack2Available=b.Pack2Available; x.Pressurization.BleedSource1=b.Engine1Source or b.APUSource; x.Pressurization.BleedSource2=b.Engine2Source or b.APUSource; x.Pressurization.SourceAvailable=b.SourceAvailable
 end
end
return BleedAir
