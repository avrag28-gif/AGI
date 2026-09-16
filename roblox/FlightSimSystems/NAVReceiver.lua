-- FlightSim NAV receiver manager v0.1
-- Centralizes NAV1/NAV2 receiver ownership. NAV1 may select ILS or VOR; NAV2 is VOR-only.
local NAVReceiver={}; NAVReceiver.__index=NAVReceiver
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function match(a,b) return finite(a) and finite(b) and math.abs(a-b)<0.005 end
local function clear(n,i)
 local p="NAV"..i; n[p.."Receiver"]="NONE"; n[p.."Ident"]=nil; n[p.."Frequency"]=nil; n[p.."Signal"]=nil
end
function NAVReceiver.new(state) return setmetatable({state=state},NAVReceiver) end
function NAVReceiver:Step(dt)
 local x=self.state:Get(); local n=x.Navigation or {}; local powered=x.Avionics and x.Avionics.Radios==true
 local r=n.ApproachRunway; local tuned1=tonumber(x.Radios and x.Radios.NAV1); local tuned2=tonumber(x.Radios and x.Radios.NAV2)
 if not powered then clear(n,1); clear(n,2); n.NAV1Receiver="NONE"; n.NAV2Receiver="NONE"; n.ILS=nil; n.VOR=nil; n.VOR2=nil; return true end
 -- NAV1 priority is explicit: a valid tuned ILS is selected first; otherwise VOR may be selected.
 local ilsValid=r and finite(r.ILSFrequency) and match(tuned1,r.ILSFrequency)
 if ilsValid then n.NAV1Receiver="ILS"; n.NAV1Ident=r.ILSIdent; n.NAV1Frequency=r.ILSFrequency
 else
  local station=n.VORStation
  if station and match(tuned1,station.Frequency) then n.NAV1Receiver="VOR"; n.NAV1Ident=station.Ident; n.NAV1Frequency=station.Frequency
  else clear(n,1) end
 end
 -- NAV2 is independently assigned to its configured VOR station.
 local station2=n.VORStationNAV2
 if station2 and match(tuned2,station2.Frequency) then n.NAV2Receiver="VOR"; n.NAV2Ident=station2.Ident; n.NAV2Frequency=station2.Frequency else clear(n,2) end
 return true
end
return NAVReceiver
