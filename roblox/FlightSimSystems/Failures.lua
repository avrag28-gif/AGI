-- FlightSim failure manager foundation v0.4
-- Server-authoritative failure state. Test/admin code should call Set* methods;
-- player input must never be allowed to inject failures directly.
local Failures={}; Failures.__index=Failures
local function ensure(x)
 x.Failures=x.Failures or {}
 x.Failures.Engines=x.Failures.Engines or {[1]={Active=false,Reason=nil,Fire=false},[2]={Active=false,Reason=nil,Fire=false}}
 for i=1,2 do
  x.Failures.Engines[i].Fire=x.Failures.Engines[i].Fire==true
  x.Failures.Engines[i].Active=x.Failures.Engines[i].Active==true
 end
 x.Failures.Hydraulic=x.Failures.Hydraulic or {A=false,B=false}
 x.Failures.Electrical=x.Failures.Electrical or {Bus1=false,Bus2=false,APU=false}
 x.Failures.FlightControls=x.Failures.FlightControls or {Aileron=false,Elevator=false,Rudder=false}
 x.Failures.FireProtection=x.Failures.FireProtection or {Engines={[1]={Fire=false},[2]={Fire=false}},APU={Fire=false}}
 for i=1,2 do
  x.Failures.FireProtection.Engines[i]=x.Failures.FireProtection.Engines[i] or {Fire=false}
  x.Failures.FireProtection.Engines[i].Fire=x.Failures.FireProtection.Engines[i].Fire==true
 end
 x.Failures.FireProtection.APU=x.Failures.FireProtection.APU or {Fire=false}
 x.Failures.FireProtection.APU.Fire=x.Failures.FireProtection.APU.Fire==true
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
function Failures:SetEngineFire(index,active)
 local x=self.state:Get(); local f=ensure(x); index=tonumber(index)
 if index~=1 and index~=2 then return false,"invalid_engine" end
 f.Engines[index].Fire=active==true
 f.FireProtection.Engines[index].Fire=active==true
 return true
end
function Failures:SetAPUFire(active)
 local x=self.state:Get(); local f=ensure(x); f.FireProtection.APU.Fire=active==true; return true
end
function Failures:SetHydraulic(system,active)
 local x=self.state:Get(); local f=ensure(x)
 if system~="A" and system~="B" then return false,"invalid_hydraulic" end
 f.Hydraulic[system]=active==true
 return true
end
function Failures:SetElectrical(system,active)
 local x=self.state:Get(); local f=ensure(x)
 if system~="Bus1" and system~="Bus2" and system~="APU" then return false,"invalid_electrical" end
 f.Electrical[system]=active==true
 return true
end
function Failures:SetFlightControl(surface,active)
 local x=self.state:Get(); local f=ensure(x)
 if surface~="Aileron" and surface~="Elevator" and surface~="Rudder" then return false,"invalid_surface" end
 f.FlightControls[surface]=active==true
 return true
end
function Failures:Step(dt)
 local x=self.state:Get(); local f=ensure(x)
 x.FailureEffects=x.FailureEffects or {AileronAuthority=1,ElevatorAuthority=1,RudderAuthority=1}
 for i=1,2 do
  local e=x.Engines[i]; local ef=f.Engines[i]
  if ef.Active then
   e.FuelOn=false; e.Ignition=false; e.Starter=false; e.Running=false; e.Thrust=0; e.FuelFlow=0; e.GeneratorAvailable=false
  end
 end
 if f.Hydraulic.A then x.Hydraulic.A=0 end
 if f.Hydraulic.B then x.Hydraulic.B=0 end
 if f.Electrical.Bus1 then x.Electrical.Bus1=false end
 if f.Electrical.Bus2 then x.Electrical.Bus2=false end
 if f.Electrical.APU then x.Electrical.APU=false end
 x.FailureEffects.AileronAuthority=f.FlightControls.Aileron and 0 or 1
 x.FailureEffects.ElevatorAuthority=f.FlightControls.Elevator and 0 or 1
 x.FailureEffects.RudderAuthority=f.FlightControls.Rudder and 0 or 1
end
return Failures
