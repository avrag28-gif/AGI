-- FlightSim ATC / clearance-delivery controller v0.3
-- Game simulation of controller workflow; not a real-world ATC service.
local ATC={}; ATC.__index=ATC
local PHASES={COLD=true,PUSHBACK=true,TAXI=true,TAKEOFF=true,DEPARTURE=true,ENROUTE=true,ARRIVAL=true,APPROACH=true,LANDING=true,GO_AROUND=true}
local FACILITIES={DELIVERY=true,GROUND=true,TOWER=true,DEPARTURE=true,CENTER=true,APPROACH=true}
local function ensure(x)
 x.ATC=x.ATC or {Facility="GROUND",Phase="COLD",Callsign="FLIGHT",Clearance=nil,PendingReadback=nil,LastMessage="",LastResult="",Squawk="2000",AssignedFrequency=121.7,AssignedRunway=nil,AssignedHeading=nil,AssignedAltitude=nil,AssignedSpeed=nil,ClearanceValid=false,ReadbackValid=false,Sequence=0}
 return x.ATC
end
local function normalize(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
local function validSquawk(v)
 local s=normalize(v); return #s==4 and not s:find("[^0-7]") and not s:find("[89]")
end
local function generateSquawk(seed)
 local n=(tonumber(seed) or 0)%4096; local d1=math.floor(n/512)%8; local d2=math.floor(n/64)%8; local d3=math.floor(n/8)%8; local d4=n%8; return string.format("%d%d%d%d",d1,d2,d3,d4)
end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function ATC.new(state) return setmetatable({state=state},ATC) end
function ATC:SetCallsign(callsign) local c=normalize(callsign); if #c<2 or #c>12 then return false,"invalid_callsign" end; ensure(self.state:Get()).Callsign=c; return true end
function ATC:SetFacility(facility) local f=string.upper(tostring(facility)); if not FACILITIES[f] then return false,"invalid_atc_facility" end; ensure(self.state:Get()).Facility=f; return true end
function ATC:SetPhase(phase) phase=string.upper(tostring(phase)); if not PHASES[phase] then return false,"invalid_atc_phase" end; ensure(self.state:Get()).Phase=phase; return true end
function ATC:RequestClearance(kind)
 local x=self.state:Get(); local a=ensure(x); kind=string.upper(tostring(kind or "DEPARTURE")); local phase=a.Phase
 if kind=="DEPARTURE" then
  if phase~="COLD" and phase~="PUSHBACK" and phase~="TAXI" then return false,"departure_clearance_not_available" end
  local dest=normalize(x.FMC and x.FMC.Destination or "DEST"); local rawAlt=tonumber(x.FMC and x.FMC.CruiseAltitude) or 10000; local alt=math.floor(math.clamp(finite(rawAlt) and rawAlt or 10000,3000,41000)/100)*100
  local squawk=generateSquawk((x.FMC and x.FMC.Sequence) or a.Sequence+1); if not validSquawk(squawk) then squawk="2000" end
  a.Squawk=squawk; a.AssignedFrequency=121.7; a.AssignedAltitude=alt; a.AssignedSpeed=nil; a.AssignedHeading=nil; a.AssignedRunway=x.Navigation and x.Navigation.ApproachRunway or nil
  a.Clearance={Type="DEPARTURE",Destination=dest,Altitude=alt,Frequency=a.AssignedFrequency,Squawk=squawk,Runway=a.AssignedRunway,Sequence=a.Sequence+1}; a.Sequence+=1; a.PendingReadback=a.Clearance; a.ClearanceValid=false; a.ReadbackValid=false
  a.LastMessage=string.format("CLEARED TO %s, CLIMB %d, SQUAWK %s, CONTACT GROUND %.3f",dest,alt,squawk,a.AssignedFrequency); a.LastResult="CLEARANCE_ISSUED"; return true,a.LastMessage
 elseif kind=="TAXI" then
  if phase~="PUSHBACK" and phase~="TAXI" and phase~="COLD" then return false,"taxi_clearance_not_available" end
  local runway=normalize(a.AssignedRunway or (x.Navigation and x.Navigation.ApproachRunway) or "ACTIVE RUNWAY"); a.AssignedRunway=runway; a.AssignedFrequency=121.7
  a.Clearance={Type="TAXI",Runway=runway,Frequency=a.AssignedFrequency,Sequence=a.Sequence+1}; a.Sequence+=1; a.PendingReadback=a.Clearance; a.ClearanceValid=false; a.ReadbackValid=false; a.LastMessage="TAXI TO "..runway.." VIA ASSIGNED ROUTE"; a.LastResult="CLEARANCE_ISSUED"; return true,a.LastMessage
 elseif kind=="TAKEOFF" then
  if phase~="TAXI" and phase~="TAKEOFF" then return false,"takeoff_clearance_not_available" end
  local runway=normalize(a.AssignedRunway or (x.Navigation and x.Navigation.ApproachRunway) or "RUNWAY"); a.AssignedRunway=runway; a.AssignedFrequency=118.0
  a.Clearance={Type="TAKEOFF",Runway=runway,Frequency=a.AssignedFrequency,Sequence=a.Sequence+1}; a.Sequence+=1; a.PendingReadback=a.Clearance; a.ClearanceValid=false; a.ReadbackValid=false; a.LastMessage="CLEARED FOR TAKEOFF "..runway; a.LastResult="CLEARANCE_ISSUED"; return true,a.LastMessage
 elseif kind=="APPROACH" then
  if phase~="ARRIVAL" and phase~="APPROACH" and phase~="ENROUTE" then return false,"approach_clearance_not_available" end
  local runway=normalize(a.AssignedRunway or (x.Navigation and x.Navigation.ApproachRunway) or "RUNWAY"); a.AssignedRunway=runway; a.AssignedFrequency=118.0
  a.Clearance={Type="APPROACH",Runway=runway,Frequency=a.AssignedFrequency,Sequence=a.Sequence+1}; a.Sequence+=1; a.PendingReadback=a.Clearance; a.ClearanceValid=false; a.ReadbackValid=false; a.LastMessage="CLEARED "..runway.." APPROACH, CONTACT TOWER"; a.LastResult="CLEARANCE_ISSUED"; return true,a.LastMessage
 elseif kind=="LANDING" then
  if phase~="APPROACH" and phase~="LANDING" then return false,"landing_clearance_not_available" end
  local runway=normalize(a.AssignedRunway or (x.Navigation and x.Navigation.ApproachRunway) or "RUNWAY"); a.AssignedRunway=runway; a.AssignedFrequency=118.0
  a.Clearance={Type="LANDING",Runway=runway,Frequency=a.AssignedFrequency,Sequence=a.Sequence+1}; a.Sequence+=1; a.PendingReadback=a.Clearance; a.ClearanceValid=false; a.ReadbackValid=false; a.LastMessage="CLEARED TO LAND "..runway; a.LastResult="CLEARANCE_ISSUED"; return true,a.LastMessage
 end
 return false,"unsupported_clearance_type"
end
function ATC:Readback(payload)
 local a=ensure(self.state:Get()); if not a.PendingReadback then return false,"no_pending_clearance" end; if type(payload)~="table" then return false,"invalid_readback" end
 local p=a.PendingReadback; local ok=false
 if p.Type=="DEPARTURE" then ok=normalize(payload.Destination)==normalize(p.Destination) and tonumber(payload.Altitude)==tonumber(p.Altitude) and normalize(payload.Squawk)==normalize(p.Squawk)
 elseif p.Type=="TAXI" or p.Type=="TAKEOFF" or p.Type=="APPROACH" or p.Type=="LANDING" then ok=normalize(payload.Runway)==normalize(p.Runway)
 end
 a.ReadbackValid=ok; a.ClearanceValid=ok; a.LastResult=ok and "READBACK_ACCEPTED" or "READBACK_REJECTED"; if ok then a.PendingReadback=nil end; return ok,a.LastResult
end
function ATC:Step(dt)
 local x=self.state:Get(); local a=ensure(x); if x.Transponder then x.Transponder.Code=a.Squawk end
 if a.Clearance and a.Clearance.Type=="DEPARTURE" and a.ReadbackValid and x.Transponder then x.Transponder.Mode="ALT" end
 a.Phase=a.Phase or "COLD"
end
return ATC
