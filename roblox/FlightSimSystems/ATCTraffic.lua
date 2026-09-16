-- FlightSim ATC traffic / runway occupancy foundation v0.2
-- Server-authoritative game-simulation coordination; not real-world separation minima.
local ATCTraffic={}; ATCTraffic.__index=ATCTraffic
local STATES={VACANT=true,RESERVED=true,OCCUPIED=true,HOLD_SHORT=true}
local OPERATIONS={TAKEOFF=true,LANDING=true,CROSSING=true}
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+"," "):gsub("%s+$","") end
local function validKey(v) local s=norm(v); return s~="" and #s<=32 and s or nil end
function ATCTraffic.new() return setmetatable({runways={},sequence=0},ATCTraffic) end
function ATCTraffic:RegisterRunway(runwayId)
 local id=validKey(runwayId); if not id then return false,"invalid_runway" end
 if not self.runways[id] then self.runways[id]={Id=id,State="VACANT",AircraftId=nil,Callsign=nil,Operation=nil,Sequence=0} end
 return true,self.runways[id]
end
function ATCTraffic:GetRunway(runwayId) return self.runways[validKey(runwayId)] end
function ATCTraffic:Reserve(runwayId,aircraftId,callsign,operation)
 local runway=self:GetRunway(runwayId); if not runway then return false,"runway_not_registered" end
 local aid=validKey(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 local op=string.upper(tostring(operation or "")); if not OPERATIONS[op] then return false,"invalid_operation" end
 if runway.State=="OCCUPIED" and runway.AircraftId~=aid then return false,"runway_occupied" end
 if runway.State=="RESERVED" and runway.AircraftId~=aid then return false,"runway_reserved" end
 if runway.State=="HOLD_SHORT" and runway.AircraftId~=aid then return false,"runway_hold_short" end
 self.sequence+=1; runway.State="RESERVED"; runway.AircraftId=aid; runway.Callsign=validKey(callsign) or aid; runway.Operation=op; runway.Sequence=self.sequence; return true,runway
end
function ATCTraffic:SetOccupied(runwayId,aircraftId)
 local runway=self:GetRunway(runwayId); if not runway then return false,"runway_not_registered" end; local aid=validKey(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 if runway.State~="RESERVED" or runway.AircraftId~=aid then return false,"runway_not_reserved_by_aircraft" end; runway.State="OCCUPIED"; return true,runway
end
function ATCTraffic:SetHoldShort(runwayId,aircraftId,callsign)
 local runway=self:GetRunway(runwayId); if not runway then return false,"runway_not_registered" end; local aid=validKey(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 if runway.State=="OCCUPIED" and runway.AircraftId~=aid then return false,"runway_occupied" end; if runway.State=="RESERVED" and runway.AircraftId~=aid then return false,"runway_reserved" end
 self.sequence+=1; runway.State="HOLD_SHORT"; runway.AircraftId=aid; runway.Callsign=validKey(callsign) or aid; runway.Operation="CROSSING"; runway.Sequence=self.sequence; return true,runway
end
function ATCTraffic:Release(runwayId,aircraftId)
 local runway=self:GetRunway(runwayId); if not runway then return false,"runway_not_registered" end; local aid=validKey(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 if runway.AircraftId~=aid then return false,"runway_owned_by_other_aircraft" end
 runway.State="VACANT"; runway.AircraftId=nil; runway.Callsign=nil; runway.Operation=nil; runway.Sequence=0; return true,runway
end
function ATCTraffic:CanIssue(runwayId,aircraftId,operation)
 local runway=self:GetRunway(runwayId); if not runway then return false,"runway_not_registered" end; local aid=validKey(aircraftId); if not aid then return false,"invalid_aircraft_id" end
 local op=string.upper(tostring(operation or "")); if not OPERATIONS[op] then return false,"invalid_operation" end
 if runway.State=="VACANT" then return true,"available" end
 if runway.AircraftId==aid and runway.Operation==op then return true,"owned" end
 return false,runway.State=="OCCUPIED" and "runway_occupied" or runway.State=="RESERVED" and "runway_reserved" or "runway_hold_short"
end
function ATCTraffic:ForEach(callback) for id,runway in pairs(self.runways) do callback(id,runway) end end
return ATCTraffic
