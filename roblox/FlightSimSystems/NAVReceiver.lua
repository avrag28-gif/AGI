-- FlightSim NAV receiver manager v0.3
-- Centralizes NAV1/NAV2 receiver ownership. Signal producers populate candidate data first.
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
 if not powered then clear(n,1); clear(n,2); return true end
 local ilsValid=r and finite(r.ILSFrequency) and match(tuned1,r.ILSFrequency) and n.ILS and n.ILS.Available==true
 local vor1=n.VORStation and match(tuned1,n.VORStation.Frequency) and n.VOR and n.VOR.Available==true
 local vor2=n.VORStationNAV2 and match(tuned2,n.VORStationNAV2.Frequency) and n.VOR2 and n.VOR2.Available==true
 -- Guidance mode requests the preferred source. Outside those modes, an available ILS/VOR may be selected automatically.
 if n.Mode=="APP" and ilsValid then n.NAV1Receiver="ILS"; n.NAV1Ident=r.ILSIdent; n.NAV1Frequency=r.ILSFrequency
 elseif n.Mode=="VOR" and vor1 then n.NAV1Receiver="VOR"; n.NAV1Ident=n.VOR.Ident; n.NAV1Frequency=n.VOR.Frequency
 elseif ilsValid then n.NAV1Receiver="ILS"; n.NAV1Ident=r.ILSIdent; n.NAV1Frequency=r.ILSFrequency
 elseif vor1 then n.NAV1Receiver="VOR"; n.NAV1Ident=n.VOR.Ident; n.NAV1Frequency=n.VOR.Frequency
 else clear(n,1) end
 if vor2 then n.NAV2Receiver="VOR"; n.NAV2Ident=n.VOR2.Ident; n.NAV2Frequency=n.VOR2.Frequency else clear(n,2) end
 if n.NAV1Receiver=="ILS" then n.NAV1Signal=n.ILS elseif n.NAV1Receiver=="VOR" then n.NAV1Signal=n.VOR else n.NAV1Signal=nil end
 if n.NAV2Receiver=="VOR" then n.NAV2Signal=n.VOR2 else n.NAV2Signal=nil end
 return true
end
return NAVReceiver
