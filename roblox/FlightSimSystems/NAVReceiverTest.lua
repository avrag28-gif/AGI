-- FlightSim NAV1 receiver ownership contract tests v0.1
-- Deterministic state-level checks; no Roblox runtime/test runner is invoked here.
local Test={}
local function check(condition,message) if not condition then error(message,2) end end
function Test.Validate(state)
 local n=state.Navigation or {}
 local source=n.NAV1Receiver
 check(source=="NONE" or source=="VOR" or source=="ILS","invalid NAV1 receiver source")
 if source=="ILS" then
  check(n.ILS and n.ILS.Available==true,"ILS receiver owns NAV1 without an available ILS signal")
  check(not n.VOR,"VOR output must be cleared while ILS owns NAV1")
 elseif source=="VOR" then
  check(n.VOR and n.VOR.Available==true,"VOR receiver owns NAV1 without an available VOR signal")
  check(not (n.ILS and n.ILS.Available==true),"ILS output must not remain active while VOR owns NAV1")
 end
 return true
end
function Test.ValidateMutualExclusion(state)
 local n=state.Navigation or {}
 check(not (n.ILS and n.ILS.Available==true and n.VOR and n.VOR.Available==true),"NAV1 cannot expose active ILS and VOR simultaneously")
 return true
end
return Test
