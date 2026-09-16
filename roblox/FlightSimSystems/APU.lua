-- FlightSim APU system v0.1
-- Simulation approximation: APU start/spool, generator availability and shutdown.
local APU={}; APU.__index=APU
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function APU.new(state) return setmetatable({state=state},APU) end
function APU:Step(dt)
 local x=self.state:Get(); local e=x.Electrical; local f=x.Failures and x.Failures.Electrical or {}
 x.APUState=x.APUState or {Running=false,Starter=false,RPM=0,EGT=20,GeneratorAvailable=false,StartFailed=false}
 local a=x.APUState
 local requested=e.APU==true and not f.APU
 a.StartFailed=false
 if requested then
  if a.RPM<95 then a.Starter=true; a.RPM=clamp(a.RPM+35*dt,0,100) else a.Starter=false end
  if a.RPM>=60 then a.Running=true; a.EGT=clamp(a.EGT+180*dt,20,650) end
 else
  a.Starter=false; a.Running=false; a.RPM=clamp(a.RPM-45*dt,0,100); a.EGT=clamp(a.EGT-100*dt,20,650)
 end
 a.GeneratorAvailable=a.Running and not f.APU
 x.APUState=a
 -- Electrical.lua consumes this explicit generator state; the cockpit switch remains e.APU.
 e.APUGeneratorAvailable=a.GeneratorAvailable
end
return APU
