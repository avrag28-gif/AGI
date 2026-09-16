-- FlightSim NAV receiver manager v0.4
-- Centralizes NAV1/NAV2 receiver ownership. Signal producers populate candidate data first.
local NAVReceiver={}; NAVReceiver.__index=NAVReceiver
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function match(a,b) return finite(a) and finite(b) and math.abs(a-b)<0.005 end
local function clear(n,i)
 local p="NAV"..i
 n[p.."Receiver"]="NONE"; n[p.."Ident"]=nil; n[p.."Frequency"]=nil; n[p.."Signal"]=nil
 if i==1 then n.NAV1Signal=nil elseif i==2 then n.NAV2Signal=nil end
end
local function selectReceiver(n,kind,ident,frequency,signal)
 n.NAV1Receiver=kind; n.NAV1Ident=ident; n.NAV1Frequency=frequency; n.NAV1Signal=signal
end
function NAVReceiver.new(state) return setmetatable({state=state},NAVReceiver) end
function NAVReceiver:Step(dt)
 local x=self.state:Get(); local n=x.Navigation or {}; local powered=x.Avionics and x.Avionics.Radios==true
 local r=n.ApproachRunway; local tuned1=tonumber(x.Radios and x.Radios.NAV1); local tuned2=tonumber(x.Radios and x.Radios.NAV2)
 if not powered then clear(n,1); clear(n,2); return true end
 local ilsValid=r and finite(r.ILSFrequency) and match(tuned1,r.ILSFrequency) and n.ILS and n.ILS.Available==true and n.ILS.LocalizerValid==true
 local vor1=n.VORStation and match(tuned1,n.VORStation.Frequency) and n.VOR and n.VOR.Available==true
 local vor2=n.VORStationNAV2 and match(tuned2,n.VORStationNAV2.Frequency) and n.VOR2 and n.VOR2.Available==true
 -- NAV1 selection follows the requested guidance mode. No automatic ILS selection is made outside APP,
 -- preventing an available runway ILS from silently overriding a pilot-selected VOR receiver.
 if n.Mode=="APP" then
  if ilsValid then selectReceiver(n,"ILS",r.ILSIdent,r.ILSFrequency,n.ILS) else clear(n,1) end
 elseif n.Mode=="VOR" then
  if vor1 then selectReceiver(n,"VOR",n.VOR.Ident,n.VOR.Frequency,n.VOR) else clear(n,1) end
 else
  clear(n,1)
 end
 if vor2 then n.NAV2Receiver="VOR"; n.NAV2Ident=n.VOR2.Ident; n.NAV2Frequency=n.VOR2.Frequency; n.NAV2Signal=n.VOR2 else clear(n,2) end
 return true
end
return NAVReceiver
