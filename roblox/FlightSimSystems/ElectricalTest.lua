-- FlightSim electrical subsystem contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local ElectricalTest={}
local function assertBool(v,msg) assert(type(v)=="boolean",msg) end
function ElectricalTest.ValidateBuses(state)
 local x=state:Get(); local e=x.Electrical or {}; local es=x.ElectricalState or {}
 assertBool(e.Bus1,"electrical Bus1 must be boolean")
 assertBool(e.Bus2,"electrical Bus2 must be boolean")
 assertBool(es.DualBus,"electrical dual-bus state must be boolean")
 assert(es.DualBus==(e.Bus1==true and e.Bus2==true),"dual-bus state mismatch")
 return true
end
function ElectricalTest.ValidateFailureIsolation(state)
 local x=state:Get(); local e=x.Electrical or {}; local f=x.Failures and x.Failures.Electrical or {}
 if f.Bus1==true then assert(e.Bus1~=true,"failed Bus1 must not be energized") end
 if f.Bus2==true then assert(e.Bus2~=true,"failed Bus2 must not be energized") end
 return true
end
function ElectricalTest.ValidateBattery(state)
 local x=state:Get(); local e=x.Electrical or {}
 local charge=tonumber(x.BatteryCharge) or 0
 assert(charge>=0 and charge<=1,"battery charge out of bounds")
 if charge<=0 then assert(e.Battery~=true,"depleted battery must be disconnected") end
 return true
end
function ElectricalTest.ValidateSourceTelemetry(state)
 local x=state:Get(); local e=x.Electrical or {}; local es=x.ElectricalState or {}
 assert(type(es.Source1)=="string","Bus1 source telemetry missing")
 assert(type(es.Source2)=="string","Bus2 source telemetry missing")
 assert(type(es.APUGenerator)=="boolean","APU generator telemetry missing")
 assert(type(es.LoadShed)=="boolean","load-shed telemetry missing")
 if e.Bus1~=true and e.Bus2~=true then assert(es.Source1=="NONE" and es.Source2=="NONE","unpowered buses must report no source") end
 return true
end
function ElectricalTest.ValidateAll(state)
 ElectricalTest.ValidateBuses(state)
 ElectricalTest.ValidateFailureIsolation(state)
 ElectricalTest.ValidateBattery(state)
 ElectricalTest.ValidateSourceTelemetry(state)
 return true
end
return ElectricalTest
