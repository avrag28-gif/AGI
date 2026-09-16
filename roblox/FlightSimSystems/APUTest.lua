-- FlightSim APU subsystem contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local APUTest={}
function APUTest.ValidateBounds(state)
 local x=state:Get(); local a=x.APU or {}
 local rpm=tonumber(a.RPM) or 0
 local egt=tonumber(a.EGT) or 0
 assert(rpm>=0 and rpm<=100,"APU RPM out of bounds")
 assert(egt>=20 and egt<=650,"APU EGT out of bounds")
 return true
end
function APUTest.ValidateGenerator(state)
 local x=state:Get(); local a=x.APU or {}; local e=x.Electrical or {}
 local expected=a.Running==true and (tonumber(a.RPM) or 0)>=95
 if x.Failures and x.Failures.Electrical and x.Failures.Electrical.APU==true then expected=false end
 assert((a.GeneratorAvailable==true)==expected,"APU generator availability mismatch")
 if a.GeneratorAvailable==true then assert(e.APUGeneratorAvailable==true,"electrical APU generator flag missing") end
 return true
end
function APUTest.ValidateFailure(state)
 local x=state:Get(); local a=x.APU or {}; local f=x.Failures and x.Failures.Electrical or {}
 if f.APU==true then
  assert(a.GeneratorAvailable~=true,"failed APU must not provide generator")
 end
 return true
end
function APUTest.ValidateAll(state)
 APUTest.ValidateBounds(state)
 APUTest.ValidateGenerator(state)
 APUTest.ValidateFailure(state)
 return true
end
return APUTest
