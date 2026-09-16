-- FlightSim authoritative failure-state schema v0.1
-- Keeps State.lua compact while guaranteeing every failure domain exists before systems consume it.
local FailureSchema={}
function FailureSchema.Apply(x)
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
 return x.Failures
end
return FailureSchema
