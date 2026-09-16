-- FlightSim authoritative failure-state schema v0.2
-- FailureSchema owns shape/defaults only; Failures.lua derives FailureEffects, while subsystems own physical state.
local FailureSchema={}
local function apply(x)
 x.Failures=x.Failures or {}
 x.Failures.Engines=x.Failures.Engines or {[1]={Active=false,Reason=nil,Fire=false},[2]={Active=false,Reason=nil,Fire=false}}
 for i=1,2 do x.Failures.Engines[i]=x.Failures.Engines[i] or {Active=false,Reason=nil,Fire=false}; x.Failures.Engines[i].Active=x.Failures.Engines[i].Active==true; x.Failures.Engines[i].Fire=x.Failures.Engines[i].Fire==true end
 x.Failures.Hydraulic=x.Failures.Hydraulic or {A=false,B=false}
 x.Failures.Electrical=x.Failures.Electrical or {Bus1=false,Bus2=false,APU=false}
 x.Failures.FlightControls=x.Failures.FlightControls or {Aileron=false,Elevator=false,Rudder=false}
 x.Failures.FireProtection=x.Failures.FireProtection or {Engines={[1]={Fire=false},[2]={Fire=false}},APU={Fire=false}}
 x.Failures.FireProtection.Engines=x.Failures.FireProtection.Engines or {[1]={Fire=false},[2]={Fire=false}}
 for i=1,2 do x.Failures.FireProtection.Engines[i]=x.Failures.FireProtection.Engines[i] or {Fire=false}; x.Failures.FireProtection.Engines[i].Fire=x.Failures.FireProtection.Engines[i].Fire==true end
 x.Failures.FireProtection.APU=x.Failures.FireProtection.APU or {Fire=false}; x.Failures.FireProtection.APU.Fire=x.Failures.FireProtection.APU.Fire==true
 x.Failures.Pressurization=x.Failures.Pressurization or {Pack1=false,Pack2=false,OutflowValve=false}
 x.Failures.AntiIce=x.Failures.AntiIce or {Engine1=false,Engine2=false,Wing=false}
 x.FailureEffects=x.FailureEffects or {}
 local e=x.FailureEffects
 e.Engine1Failed=e.Engine1Failed==true; e.Engine2Failed=e.Engine2Failed==true
 e.HydraulicAFailed=e.HydraulicAFailed==true; e.HydraulicBFailed=e.HydraulicBFailed==true
 e.ElectricalBus1Failed=e.ElectricalBus1Failed==true; e.ElectricalBus2Failed=e.ElectricalBus2Failed==true; e.ElectricalAPUFailed=e.ElectricalAPUFailed==true
 e.AileronAuthority=tonumber(e.AileronAuthority) or 1; e.ElevatorAuthority=tonumber(e.ElevatorAuthority) or 1; e.RudderAuthority=tonumber(e.RudderAuthority) or 1
 e.Engine1Fire=e.Engine1Fire==true; e.Engine2Fire=e.Engine2Fire==true; e.APUFire=e.APUFire==true
 e.Pack1Failed=e.Pack1Failed==true; e.Pack2Failed=e.Pack2Failed==true; e.OutflowValveFailed=e.OutflowValveFailed==true
 e.AntiIceEngine1Failed=e.AntiIceEngine1Failed==true; e.AntiIceEngine2Failed=e.AntiIceEngine2Failed==true; e.AntiIceWingFailed=e.AntiIceWingFailed==true
 return x.Failures
end
function FailureSchema.Apply(x) return apply(x) end
return FailureSchema
