-- FlightSim ATC takeoff / landing sequencing foundation v0.2
-- Deterministic queueing and runway-clearance gating for the game simulation.
local ATCSequencer={}; ATCSequencer.__index=ATCSequencer
local OPS={TAKEOFF=true,LANDING=true,CROSSING=true}
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+"," "):gsub("%s+$","") end
local function key(v) local s=norm(v); return s~="" and #s<=32 and s or nil end
function ATCSequencer.new(traffic) return setmetatable({traffic=traffic,queues={},sequence=0},ATCSequencer) end
function ATCSequencer:_queue(runwayId)
 local id=key(runwayId); if not id then return nil,"invalid_runway" end
 self.queues[id]=self.queues[id] or {}; return self.queues[id]
end
function ATCSequencer:Enqueue(runwayId,aircraftId,callsign,operation)
 local q,err=self:_queue(runwayId); if not q then return false,err end
 local aid=key(aircraftId); local op=string.upper(tostring(operation or "")); if not aid then return false,"invalid_aircraft_id" end; if not OPS[op] then return false,"invalid_operation" end
 for _,entry in ipairs(q) do if entry.AircraftId==aid then return false,"aircraft_already_queued" end end
 if self.traffic and self.traffic.GetRunway then
  local runway=self.traffic:GetRunway(key(runwayId))
  if runway and runway.AircraftId==aid and runway.State~="VACANT" then return false,"aircraft_already_active" end
 end
 self.sequence+=1; local entry={AircraftId=aid,Callsign=key(callsign) or aid,Operation=op,Sequence=self.sequence}; q[#q+1]=entry; return true,entry
end
function ATCSequencer:Peek(runwayId)
 local q,err=self:_queue(runwayId); if not q then return nil,err end; return q[1]
end
function ATCSequencer:Remove(runwayId,aircraftId)
 local q,err=self:_queue(runwayId); if not q then return false,err end; local aid=key(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 for i,e in ipairs(q) do if e.AircraftId==aid then table.remove(q,i); return true,e end end
 return false,"aircraft_not_queued"
end
function ATCSequencer:GrantNext(runwayId)
 local q,err=self:_queue(runwayId); if not q then return false,err end; local entry=q[1]; if not entry then return false,"queue_empty" end
 local ok,reason=self.traffic:CanIssue(runwayId,entry.AircraftId,entry.Operation); if not ok then return false,reason end
 local reserved,res=self.traffic:Reserve(runwayId,entry.AircraftId,entry.Callsign,entry.Operation); if not reserved then return false,res end
 table.remove(q,1); return true,res
end
function ATCSequencer:CanProceed(runwayId,aircraftId)
 local entry=self:Peek(runwayId); if not entry or entry.AircraftId~=key(aircraftId) then return false,"not_next_in_sequence" end
 return self.traffic:CanIssue(runwayId,aircraftId,entry.Operation)
end
function ATCSequencer:QueueLength(runwayId)
 local q=self:_queue(runwayId); return q and #q or 0
end
return ATCSequencer
