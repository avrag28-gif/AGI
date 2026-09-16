-- FlightSim failure manager foundation v0.6
-- Server-authoritative failure state. This module owns failure state/effects only;
-- subsystem modules own the physical response to those failures.
local Failures={}; Failures.__index=Failures
local function ensure(x)
 x.Failures=x.Failures or {}
 x.Failures.Engines=x.Failures.Engines or {[1]={Active=false,Reason=nil,Fire=false},[2]={Active=false,Reason=nil,Fire=false}}
 for i=1,2 do x.Failures.Engines[i]=x.Failures.Engines[i] or {Active=false,Reason=nil,Fire=false}; x.Failures.Engines[i].Fire=x.Failures.Engines[i].Fire==true; x.Failures.Engines[i].Active=x.Failures.Engines[i].Active==true end
 x.Failures.Hydraulic=x.Failures.Hydraulic or {A=false,B=false}; x.Failures.Electrical=x.Failures.Electrical or {Bus1=false,Bus2=false,APU=false}; x.Failures.FlightControls=x.Failures.FlightControls or {Aileron=false,Elevator=false,Rudder=false}
 x.Failures.FireProtection=x.Failures.FireProtection or {}; x.Failures.FireProtection.Engines=x.Failures.FireProtection.Engines or {[1]={Fire=false},[2]={Fire=false}}; x.Failures.FireProtection.APU=x.Failures.FireProtection.APU or {Fire=false}
 for i=1,2 do x.Failures.FireProtection.Engines[i]=x.Failures.FireProtection.Engines[i] or {Fire=false}; x.Failures.FireProtection.Engines[i].Fire=x.Failures.FireProtection.Engines[i].Fire==true end
 x.Failures.FireProtection.APU.Fire=x.Failures.FireProtection.APU.Fire==true
 x.Failures.Pressurization=x.Failures.Pressurization or {Pack1=false,Pack2=false,OutflowValve=false}; x.Failures.AntiIce=x.Failures.AntiIce or {Engine1=false,Engine2=false,Wing=false}
 x.FailureEffects=x.FailureEffects or {}
 return x.Failures,x.FailureEffects
end
function Failures.new(state) return setmetatable({state=state},Failures) end
function Failures:SetEngine(index,active,reason) local x=self.state:Get(); local f=ensure(x); index=tonumber(index); if index~=1 and index~=2 then return false,"invalid_engine" end; f.Engines[index].Active=active==true; f.Engines[index].Reason=f.Engines[index].Active and (reason or "UNKNOWN") or nil; return true end
function Failures:SetEngineFire(index,active) local x=self.state:Get(); local f=ensure(x); index=tonumber(index); if index~=1 and index~=2 then return false,"invalid_engine" end; f.Engines[index].Fire=active==true; f.FireProtection.Engines[index].Fire=active==true; return true end
function Failures:SetAPUFire(active) local x=self.state:Get(); local f=ensure(x); f.FireProtection.APU.Fire=active==true; return true end
function Failures:SetHydraulic(system,active) local x=self.state:Get(); local f=ensure(x); if system~="A" and system~="B" then return false,"invalid_hydraulic" end; f.Hydraulic[system]=active==true; return true end
function Failures:SetElectrical(system,active) local x=self.state:Get(); local f=ensure(x); if system~="Bus1" and system~="Bus2" and system~="APU" then return false,"invalid_electrical" end; f.Electrical[system]=active==true; return true end
function Failures:SetFlightControl(surface,active) local x=self.state:Get(); local f=ensure(x); if surface~="Aileron" and surface~="Elevator" and surface~="Rudder" then return false,"invalid_surface" end; f.FlightControls[surface]=active==true; return true end
function Failures:SetPressurization(kind,active) local x=self.state:Get(); local f=ensure(x); if f.Pressurization[kind]==nil then return false,"invalid_pressurization_failure" end; f.Pressurization[kind]=active==true; return true end
function Failures:SetAntiIce(kind,active) local x=self.state:Get(); local f=ensure(x); if f.AntiIce[kind]==nil then return false,"invalid_antiice_failure" end; f.AntiIce[kind]=active==true; return true end
function Failures:Step(dt)
 local x=self.state:Get(); local f,e=ensure(x)
 -- Rebuild derived effects every tick. No subsystem physical state is mutated here.
 e.Engine1Failed=f.Engines[1].Active; e.Engine2Failed=f.Engines[2].Active
 e.HydraulicAFailed=f.Hydraulic.A==true; e.HydraulicBFailed=f.Hydraulic.B==true
 e.ElectricalBus1Failed=f.Electrical.Bus1==true; e.ElectricalBus2Failed=f.Electrical.Bus2==true; e.ElectricalAPUFailed=f.Electrical.APU==true
 e.AileronAuthority=f.FlightControls.Aileron and 0 or 1; e.ElevatorAuthority=f.FlightControls.Elevator and 0 or 1; e.RudderAuthority=f.FlightControls.Rudder and 0 or 1
 e.Engine1Fire=f.Engines[1].Fire or f.FireProtection.Engines[1].Fire; e.Engine2Fire=f.Engines[2].Fire or f.FireProtection.Engines[2].Fire; e.APUFire=f.FireProtection.APU.Fire==true
 e.Pack1Failed=f.Pressurization.Pack1==true; e.Pack2Failed=f.Pressurization.Pack2==true; e.OutflowValveFailed=f.Pressurization.OutflowValve==true
 e.AntiIceEngine1Failed=f.AntiIce.Engine1==true; e.AntiIceEngine2Failed=f.AntiIce.Engine2==true; e.AntiIceWingFailed=f.AntiIce.Wing==true
 x.FailureEffects=e
end
return Failures
