-- FlightSim failure manager foundation v0.1
local Failures={}; Failures.__index=Failures
local function ensure(x)
 x.Failures=x.Failures or {}
 x.Failures.Engines=x.Failures.Engines or {[1]={Active=false,Reason=nil},[2]={Active=false,Reason=nil}}
 return x.Failures
end
function Failures.new(state) return setmetatable({state=state},Failures) end
function Failures:SetEngine(index,active,reason)
 local x=self.state:Get(); local f=ensure(x); index=tonumber(index)
 if index~=1 and index~=2 then return false,"invalid_engine" end
 f.Engines[index].Active=active==true
 f.Engines[index].Reason=f.Engines[index].Active and (reason or "UNKNOWN") or nil
 return true
end
function Failures:Step(dt)
 local x=self.state:Get(); local f=ensure(x)
 for i=1,2 do
  local e=x.Engines[i]; local ef=f.Engines[i]
  if ef.Active then
   e.FuelOn=false; e.Ignition=false; e.Starter=false; e.Running=false
   e.Thrust=0; e.FuelFlow=0; e.GeneratorAvailable=false
  end
 end
end
return Failures
