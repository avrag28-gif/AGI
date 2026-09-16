-- FlightSim runway clearance coordinator v0.2
-- Coordinates runway reservations with deterministic sequencing; not real-world ATC separation.
local ATCRunway={}; ATCRunway.__index=ATCRunway
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
local function ensure(x)
 x.ATC=x.ATC or {}; x.ATC.Runway=x.ATC.Runway or {Clearance=nil,ReservationState="VACANT",Runway=nil,Sequence=0,LastResult="",Queued=false}; return x.ATC.Runway
end
function ATCRunway.new(state,traffic,aircraftId,callsign,sequencer) return setmetatable({state=state,traffic=traffic,aircraftId=norm(aircraftId),callsign=norm(callsign),sequencer=sequencer},ATCRunway) end
function ATCRunway:SetIdentity(aircraftId,callsign) self.aircraftId=norm(aircraftId); self.callsign=norm(callsign); return self.aircraftId~="" and self.callsign~="" end
function ATCRunway:_request(runway,operation)
 local x=self.state:Get(); local r=ensure(x); if runway=="" then return false,"invalid_runway" end
 if not self.traffic:GetRunway(runway) then return false,"runway_not_registered" end
 if self.sequencer then
  local ok,entry=self.sequencer:Enqueue(runway,self.aircraftId,self.callsign,operation); if not ok then r.LastResult=entry; return false,entry end
  r.Runway=runway; r.Queued=true; r.ReservationState="HOLD_SHORT"; r.Sequence=entry.Sequence; r.LastResult="QUEUED"; r.Clearance="REQUEST QUEUED "..operation.." "..runway; return true,r.Clearance
 end
 local ok,reason=self.traffic:CanIssue(runway,self.aircraftId,operation); if not ok then r.LastResult=reason; return false,reason end
 local reserved,detail=self.traffic:Reserve(runway,self.aircraftId,self.callsign,operation); if not reserved then r.LastResult=detail; return false,detail end
 r.Runway=runway; r.ReservationState="RESERVED"; r.Clearance=(operation=="TAKEOFF" and "CLEARED FOR TAKEOFF " or "CLEARED TO LAND ")..runway; r.Sequence+=1; r.LastResult=operation.."_RESERVED"; return true,r.Clearance
end
function ATCRunway:RequestTakeoff(runwayId) return self:_request(norm(runwayId),"TAKEOFF") end
function ATCRunway:RequestLanding(runwayId) return self:_request(norm(runwayId),"LANDING") end
function ATCRunway:EnterRunway()
 local x=self.state:Get(); local r=ensure(x); if not r.Runway then return false,"no_runway_reservation" end
 if r.Queued then
  local ok,detail=self.sequencer:GrantNext(r.Runway); if not ok then r.LastResult=detail; return false,detail end
  r.Queued=false
 end
 local ok,detail=self.traffic:SetOccupied(r.Runway,self.aircraftId); if not ok then r.LastResult=detail; return false,detail end
 r.ReservationState="OCCUPIED"; r.LastResult="RUNWAY_OCCUPIED"; return true
end
function ATCRunway:Release()
 local x=self.state:Get(); local r=ensure(x); if not r.Runway then return false,"no_runway_reservation" end
 if r.Queued and self.sequencer then self.sequencer:Remove(r.Runway,self.aircraftId) end
 if self.traffic:GetRunway(r.Runway) and self.traffic:GetRunway(r.Runway).AircraftId==self.aircraftId then self.traffic:Release(r.Runway,self.aircraftId) end
 r.ReservationState="VACANT"; r.Clearance=nil; r.Runway=nil; r.Queued=false; r.LastResult="RUNWAY_RELEASED"; r.Sequence+=1; return true
end
function ATCRunway:Step(dt)
 local x=self.state:Get(); local r=ensure(x); if not r.Queued or not self.sequencer or not r.Runway then return end
 local ok,reason=self.sequencer:CanProceed(r.Runway,self.aircraftId); if ok then r.LastResult="NEXT_IN_SEQUENCE" else r.LastResult=reason end
end
return ATCRunway
