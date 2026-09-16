-- FlightSim NAV receiver ownership/signal contract tests v0.3
-- Deterministic state-level checks; no Roblox runtime/test runner is invoked here.
local Test={}
local function check(condition,message) if not condition then error(message,2) end end
function Test.Validate(state)
 local n=state.Navigation or {}
 local source=n.NAV1Receiver
 check(source=="NONE" or source=="VOR" or source=="ILS","invalid NAV1 receiver source")
 if source=="ILS" then
  check(n.NAV1Signal==n.ILS,"NAV1 ILS ownership must route the ILS candidate")
  check(n.ILS and n.ILS.Available==true,"ILS receiver owns NAV1 without an available ILS signal")
 elseif source=="VOR" then
  check(n.NAV1Signal==n.VOR,"NAV1 VOR ownership must route the VOR candidate")
  check(n.VOR and n.VOR.Available==true,"VOR receiver owns NAV1 without an active VOR signal")
 else
  check(n.NAV1Signal==nil,"NAV1 signal must be nil when receiver is NONE")
 end
 local nav2=n.NAV2Receiver
 check(nav2=="NONE" or nav2=="VOR" or nav2=="ILS","invalid NAV2 receiver source")
 if nav2=="VOR" then
  check(n.NAV2Signal==n.VOR2,"NAV2 VOR ownership must route the VOR2 candidate")
  check(n.VOR2 and n.VOR2.Available==true,"NAV2 VOR ownership requires an active signal")
 else
  check(n.NAV2Signal==nil,"NAV2 signal must be nil when receiver is NONE")
 end
 return true
end
function Test.ValidateModePreference(state)
 local n=state.Navigation or {}
 if n.Mode=="APP" and n.NAV1Receiver=="ILS" then check(n.ILS and n.ILS.Available==true,"APP must prefer an available ILS candidate") end
 if n.Mode=="VOR" and n.NAV1Receiver=="VOR" then check(n.VOR and n.VOR.Available==true,"VOR mode must prefer an available VOR candidate") end
 return true
end
function Test.ValidateFrequencyIsolation(state)
 local n=state.Navigation or {}
 local tuned1=tonumber(state.Radios and state.Radios.NAV1); local tuned2=tonumber(state.Radios and state.Radios.NAV2)
 if n.NAV1Receiver=="ILS" then check(n.ApproachRunway and math.abs(tuned1-n.ApproachRunway.ILSFrequency)<0.005,"NAV1 ILS frequency mismatch") end
 if n.NAV1Receiver=="VOR" then check(n.VOR and math.abs(tuned1-n.VOR.Frequency)<0.005,"NAV1 VOR frequency mismatch") end
 if n.NAV2Receiver=="VOR" then check(n.VORStationNAV2 and math.abs(tuned2-n.VORStationNAV2.Frequency)<0.005,"NAV2 VOR frequency mismatch") end
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
