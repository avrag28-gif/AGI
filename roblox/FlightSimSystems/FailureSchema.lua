-- FlightSim authoritative failure-state schema v0.3
-- FailureSchema owns shape/defaults only; Failures.lua derives FailureEffects, while subsystems own physical state.
local FailureSchema={}
local function bool(v) return v==true end
local function apply(x)
 x.Failures=x.Failures or {}
 local f=x.Failures
 f.Engines=f.Engines or {}
 for i=1,2 do f.Engines[i]=f.Engines[i] or {}; f.Engines[i].Active=bool(f.Engines[i].Active); f.Engines[i].Reason=f.Engines[i].Reason; f.Engines[i].Fire=bool(f.Engines[i].Fire) end
 f.Hydraulic=f.Hydraulic or {}; f.Hydraulic.A=bool(f.Hydraulic.A); f.Hydraulic.B=bool(f.Hydraulic.B)
 f.Electrical=f.Electrical or {}; f.Electrical.Bus1=bool(f.Electrical.Bus1); f.Electrical.Bus2=bool(f.Electrical.Bus2); f.Electrical.APU=bool(f.Electrical.APU)
 f.FlightControls=f.FlightControls or {}; f.FlightControls.Aileron=bool(f.FlightControls.Aileron); f.FlightControls.Elevator=bool(f.FlightControls.Elevator); f.FlightControls.Rudder=bool(f.FlightControls.Rudder)
 f.FireProtection=f.FireProtection or {}; f.FireProtection.Engines=f.FireProtection.Engines or {}; f.FireProtection.APU=f.FireProtection.APU or {}
 for i=1,2 do f.FireProtection.Engines[i]=f.FireProtection.Engines[i] or {}; f.FireProtection.Engines[i].Fire=bool(f.FireProtection.Engines[i].Fire) end
 f.FireProtection.APU.Fire=bool(f.FireProtection.APU.Fire)
 f.Pressurization=f.Pressurization or {}; f.Pressurization.Pack1=bool(f.Pressurization.Pack1); f.Pressurization.Pack2=bool(f.Pressurization.Pack2); f.Pressurization.OutflowValve=bool(f.Pressurization.OutflowValve)
 f.AntiIce=f.AntiIce or {}; f.AntiIce.Engine1=bool(f.AntiIce.Engine1); f.AntiIce.Engine2=bool(f.AntiIce.Engine2); f.AntiIce.Wing=bool(f.AntiIce.Wing)
 x.FailureEffects=x.FailureEffects or {}
 local e=x.FailureEffects
 e.Engine1Failed=bool(e.Engine1Failed); e.Engine2Failed=bool(e.Engine2Failed); e.HydraulicAFailed=bool(e.HydraulicAFailed); e.HydraulicBFailed=bool(e.HydraulicBFailed)
 e.ElectricalBus1Failed=bool(e.ElectricalBus1Failed); e.ElectricalBus2Failed=bool(e.ElectricalBus2Failed); e.ElectricalAPUFailed=bool(e.ElectricalAPUFailed)
 e.AileronAuthority=tonumber(e.AileronAuthority) or 1; e.ElevatorAuthority=tonumber(e.ElevatorAuthority) or 1; e.RudderAuthority=tonumber(e.RudderAuthority) or 1
 e.Engine1Fire=bool(e.Engine1Fire); e.Engine2Fire=bool(e.Engine2Fire); e.APUFire=bool(e.APUFire)
 e.Pack1Failed=bool(e.Pack1Failed); e.Pack2Failed=bool(e.Pack2Failed); e.OutflowValveFailed=bool(e.OutflowValveFailed)
 e.AntiIceEngine1Failed=bool(e.AntiIceEngine1Failed); e.AntiIceEngine2Failed=bool(e.AntiIceEngine2Failed); e.AntiIceWingFailed=bool(e.AntiIceWingFailed)
 return f
end
function FailureSchema.Apply(x) return apply(x) end
return FailureSchema
