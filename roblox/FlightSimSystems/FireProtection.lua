-- FlightSim fire protection / overheat detection foundation v0.4
-- Game simulation only; thresholds are tunable and are not certified aircraft data.
local FireProtection={}; FireProtection.__index=FireProtection
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.FireProtection=x.FireProtection or {}
 local f=x.FireProtection
 f.Engines=f.Engines or {[1]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true},[2]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true}}
 f.APU=f.APU or {Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true}; f.FireTest=f.FireTest==true
 return f
end
function FireProtection.new(state) return setmetatable({state=state},FireProtection) end
function FireProtection:Step(dt)
 local x=self.state:Get(); local f=ensure(x); local failures=x.Failures or {}; local engineFailures=failures.Engines or {}; local fpFailures=failures.FireProtection or {}; local apuFailure=fpFailures.APU or {}
 for i=1,2 do
  local e=x.Engines[i]; local d=f.Engines[i]; local ef=engineFailures[i] or {}
  local heat=math.max(0,(e.EGT or 20)-350)/700
  d.Detector=clamp(d.Detector+(heat>0.55 and 0.8 or -0.35)*dt,0,1); d.Overheat=(e.EGT or 20)>=700
  d.Fire=d.Detector>=0.8 or ef.Fire==true or (fpFailures.Engines and fpFailures.Engines[i] and fpFailures.Engines[i].Fire==true) or f.FireTest; d.Warning=d.Fire or d.Overheat
  if d.Fire and d.Armed then e.FuelOn=false; e.Ignition=false; e.Starter=false end
 end
 local apu=x.APU or {}; local a=f.APU; local apuHeat=math.max(0,(apu.EGT or 20)-250)/600
 a.Detector=clamp(a.Detector+(apuHeat>0.6 and 0.8 or -0.35)*dt,0,1); a.Overheat=(apu.EGT or 20)>=650
 a.Fire=a.Detector>=0.8 or apuFailure.Fire==true or f.FireTest; a.Warning=a.Fire or a.Overheat
 if a.Fire and a.Armed then apu.Starter=false; apu.Running=false; apu.GeneratorAvailable=false; apu.StartFailed=false; apu.RPM=clamp((tonumber(apu.RPM) or 0)-45*math.max(0,dt),0,100) end
 x.FireProtection=f; x.FireProtection.MasterWarning=f.Engines[1].Warning or f.Engines[2].Warning or f.APU.Warning or f.FireTest
 x.FireProtection.MasterFireWarning=f.Engines[1].Fire or f.Engines[2].Fire or f.APU.Fire or f.FireTest
end
return FireProtection
