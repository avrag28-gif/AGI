-- FlightSim runway operational state foundation v0.1
-- Data/state model only; authoritative occupancy is managed by ATCTraffic.
local RunwayState={}
local VALID={CLOSED=true,OPEN=true,WET=true,CONTAMINATED=true}
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
function RunwayState.Normalize(data)
 if type(data)~="table" then return nil,"invalid_runway" end
 local id=norm(data.Ident); if id=="" then return nil,"invalid_runway_ident" end
 local status=norm(data.Status or "OPEN"); if not VALID[status] then return nil,"invalid_runway_status" end
 local heading=tonumber(data.Heading); local length=tonumber(data.LengthM)
 if not heading or heading~=heading or heading<0 or heading>=360 then return nil,"invalid_runway_heading" end
 if not length or length~=length or length<=0 then return nil,"invalid_runway_length" end
 return {Ident=id,Status=status,Heading=heading,LengthM=length,WindLimited=data.WindLimited==true},nil
end
function RunwayState.IsAvailable(data)
 local r,err=RunwayState.Normalize(data); if not r then return false,err end
 if r.Status=="CLOSED" then return false,"runway_closed" end
 return true,"available"
end
return RunwayState
