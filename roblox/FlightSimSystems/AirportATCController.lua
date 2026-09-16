-- FlightSim airport ATC controller v0.1
-- Bridges validated airport data into authoritative runway/traffic state.
local AirportATCController={}; AirportATCController.__index=AirportATCController
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
function AirportATCController.new(airportData,procedureData,traffic,sequencer)
 local data,err=procedureData.Normalize(airportData); if not data then return nil,err end
 local self=setmetatable({data=data,traffic=traffic,sequencer=sequencer},AirportATCController)
 for _,r in ipairs(data.Runways) do traffic:RegisterRunway(r.Ident) end
 return self
end
function AirportATCController:GetRunway(runwayId)
 return self.procedure and self.procedure.FindRunway(self.data,runwayId) or self.data.Runways[1]
end
function AirportATCController:IsRunwayOpen(runwayId)
 local r=nil; for _,candidate in ipairs(self.data.Runways) do if norm(candidate.Ident)==norm(runwayId) then r=candidate break end end
 if not r then return false,"runway_not_found" end
 if r.Status and norm(r.Status)=="CLOSED" then return false,"runway_closed" end
 return true,r
end
function AirportATCController:Queue(runwayId,aircraftId,callsign,operation)
 local ok,runway=self:IsRunwayOpen(runwayId); if not ok then return false,runway end
 return self.sequencer:Enqueue(runway.Ident,aircraftId,callsign,operation)
end
function AirportATCController:GrantNext(runwayId)
 local ok,runway=self:IsRunwayOpen(runwayId); if not ok then return false,runway end
 return self.sequencer:GrantNext(runway.Ident)
end
function AirportATCController:CanProceed(runwayId,aircraftId)
 local ok,runway=self:IsRunwayOpen(runwayId); if not ok then return false,runway end
 return self.sequencer:CanProceed(runway.Ident,aircraftId)
end
return AirportATCController
