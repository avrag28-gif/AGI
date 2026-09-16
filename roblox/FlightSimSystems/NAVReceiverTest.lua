-- FlightSim NAV receiver ownership/signal contract tests v0.2
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
 local nav2=n.NAV2Receiver
 check(nav2=="NONE" or nav2=="VOR" or nav2=="ILS","invalid NAV2 receiver source")
 if nav2=="VOR" then check(n.VOR2 and n.VOR2.Available==true,"NAV2 VOR ownership requires an active signal") end
 return true
end
function Test.ValidateMutualExclusion(state)
 local n=state.Navigation or {}
 check(not (n.ILS and n.ILS.Available==true and n.VOR and n.VOR.Available==true),"NAV1 cannot expose active ILS and VOR simultaneously")
 return true
end
function Test.ValidateDME(state)
 local n=state.Navigation or {}
 for _,signal in ipairs({n.VOR,n.VOR2}) do
  if signal and signal.Available then
   if signal.DMEAvailable then check(type(signal.DMEDistanceNM)=="number" and signal.DMEDistanceNM>=0,"DME distance must be non-negative when DME is available") else check(signal.DMEDistanceNM==nil,"DME distance must be nil when station has no DME") end
  end
 end
 return true
end
return Test
