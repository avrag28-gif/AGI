-- FlightSim APU system v0.3
-- Simulation approximation: battery-assisted start, spool, EGT, generator and shutdown.
local APU={}; APU.__index=APU
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function APU.new(state) return setmetatable({state=state},APU) end
function APU:Step(dt)
 local x=self.state:Get(); local e=x.Electrical or {}; local f=x.Failures and x.Failures.Electrical or {}
 x.APU=x.APU or {Running=false,Starter=false,EGT=20,RPM=0,GeneratorAvailable=false,StartFailed=false}
 local a=x.APU
 local failed=f.APU==true
 local requested=e.APU==true and not failed
 local startPower=(e.Battery==true or e.ExternalPower==true or a.RPM>5) and not failed
 a.StartFailed=false
 if requested and startPower then
  if a.RPM<95 then a.Starter=true; a.RPM=clamp(a.RPM+38*dt,0,100) else a.Starter=false end
  if a.RPM>=60 then a.Running=true; a.EGT=clamp(a.EGT+170*dt,20,650) end
 elseif requested and not startPower then
  a.StartFailed=true; a.Starter=false; a.Running=false; a.GeneratorAvailable=false; a.RPM=clamp(a.RPM-30*dt,0,100)
 else
  a.Starter=false; a.Running=false; a.RPM=clamp(a.RPM-45*dt,0,100); a.EGT=clamp(a.EGT-100*dt,20,650)
 end
 if not a.Running then a.EGT=clamp(a.EGT-20*dt,20,650) end
 a.GeneratorAvailable=(a.Running==true and a.RPM>=95 and not failed)
 e.APUGeneratorAvailable=a.GeneratorAvailable
 x.APU=a
end
return APU
