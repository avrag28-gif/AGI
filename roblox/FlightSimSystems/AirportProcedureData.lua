-- FlightSim airport procedure data model v0.1
-- Data-first schema for real-world airport integration. Procedure values must be supplied
-- from a current, authoritative aeronautical dataset; this module does not invent them.
local AirportProcedureData={}
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function ident(v,max) local s=string.upper(tostring(v or "")); if #s<1 or #s>(max or 8) then return nil end; return s:match("^[A-Z0-9%-%._]+$") and s or nil end
local function copy(v) if type(v)~="table" then return v end local o={}; for k,x in pairs(v) do o[k]=copy(x) end return o end
local function validateRunway(r)
 if type(r)~="table" then return false end
 if not ident(r.Ident,3) or not finite(tonumber(r.Heading)) or tonumber(r.Heading)<0 or tonumber(r.Heading)>=360 then return false end
 if not finite(tonumber(r.LengthM)) or tonumber(r.LengthM)<300 then return false end
 if r.WidthM~=nil and (not finite(tonumber(r.WidthM)) or tonumber(r.WidthM)<10) then return false end
 if r.ElevationFt~=nil and (not finite(tonumber(r.ElevationFt)) or tonumber(r.ElevationFt)<-2000 or tonumber(r.ElevationFt)>30000) then return false end
 if r.ILSFrequency~=nil and (not finite(tonumber(r.ILSFrequency)) or tonumber(r.ILSFrequency)<108 or tonumber(r.ILSFrequency)>118) then return false end
 return true
end
local function validatePoint(p)
 return type(p)=="table" and typeof(p.Position)=="Vector3" and (p.Name==nil or ident(p.Name,8)~=nil)
end
local function validateProcedure(p,kind)
 if type(p)~="table" or not ident(p.Name,12) then return false end
 if p.Runway~=nil and not ident(p.Runway,3) then return false end
 if p.Transition~=nil and not ident(p.Transition,12) then return false end
 if type(p.Waypoints)~="table" or #p.Waypoints>64 then return false end
 for _,w in ipairs(p.Waypoints) do if not validatePoint(w) then return false end end
 if kind=="SID" or kind=="STAR" then
  if p.InitialHeading~=nil and (not finite(tonumber(p.InitialHeading)) or tonumber(p.InitialHeading)<0 or tonumber(p.InitialHeading)>=360) then return false end
 end
 return true
end
function AirportProcedureData.ValidateAirport(data)
 if type(data)~="table" then return false,"invalid_airport_data" end
 local icao=ident(data.ICAO,4); local name=ident(data.Name,32); if not icao or not name then return false,"invalid_airport_identity" end
 if type(data.Runways)~="table" or #data.Runways<1 then return false,"missing_runways" end
 for _,r in ipairs(data.Runways) do if not validateRunway(r) then return false,"invalid_runway" end end
 for _,key in ipairs({"SIDs","STARs"}) do if data[key]~=nil then if type(data[key])~="table" then return false,"invalid_"..key end; for _,p in ipairs(data[key]) do if not validateProcedure(p,key=="SIDs" and "SID" or "STAR") then return false,"invalid_procedure" end end end end
 if data.TaxiNodes~=nil then if type(data.TaxiNodes)~="table" or #data.TaxiNodes>512 then return false,"invalid_taxi_nodes" end; for _,n in ipairs(data.TaxiNodes) do if not validatePoint(n) then return false,"invalid_taxi_node" end end end
 if data.TaxiEdges~=nil then if type(data.TaxiEdges)~="table" or #data.TaxiEdges>1024 then return false,"invalid_taxi_edges" end; for _,e in ipairs(data.TaxiEdges) do if type(e)~="table" or type(e.From)~="string" or type(e.To)~="string" or (e.DistanceM~=nil and (not finite(tonumber(e.DistanceM)) or tonumber(e.DistanceM)<=0)) then return false,"invalid_taxi_edge" end end end
 return true
end
function AirportProcedureData.Normalize(data)
 local ok,err=AirportProcedureData.ValidateAirport(data); if not ok then return nil,err end
 local out=copy(data); out.ICAO=string.upper(out.ICAO); out.Name=string.upper(out.Name); out.SIDs=out.SIDs or {}; out.STARs=out.STARs or {}; out.TaxiNodes=out.TaxiNodes or {}; out.TaxiEdges=out.TaxiEdges or {}; return out
end
function AirportProcedureData.FindRunway(data,identValue)
 if type(data)~="table" or type(data.Runways)~="table" then return nil end
 local wanted=string.upper(tostring(identValue or "")); for _,r in ipairs(data.Runways) do if string.upper(tostring(r.Ident or ""))==wanted then return r end end
 return nil
end
function AirportProcedureData.FindProcedure(data,kind,name)
 local key=string.upper(tostring(kind or ""))=="SID" and "SIDs" or "STARs"; local wanted=string.upper(tostring(name or "")); for _,p in ipairs((data and data[key]) or {}) do if string.upper(tostring(p.Name or ""))==wanted then return p end end
 return nil
end
return AirportProcedureData
