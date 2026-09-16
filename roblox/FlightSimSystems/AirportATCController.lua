-- FlightSim airport ATC controller v0.2
-- Bridges validated airport data into authoritative runway/traffic state.
local AirportATCController={}; AirportATCController.__index=AirportATCController
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
function AirportATCController.new(airportData,procedureData,traffic,sequencer)
 local data,err=procedureData.Normalize(airportData); if not data then return nil,err end
 if not traffic or not sequencer then return nil,"traffic_or_sequencer_unavailable" end
 local self=setmetatable({data=data,procedureData=procedureData,traffic=traffic,sequencer=sequencer},AirportATCController)
 for _,r in ipairs(data.Runways) do local ok,e=traffic:RegisterRunway(r.Ident); if not ok then return nil,e end end
 return self
end
function AirportATCController:GetRunway(runwayId) return self.procedureData.FindRunway(self.data,runwayId) end
function AirportATCController:IsRunwayOpen(runwayId)
 local r=self:GetRunway(runwayId); if not r then return false,"runway_not_found" end
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
