-- FlightSim FMC/CDU data model v0.2
-- Validates flight-plan data before it reaches navigation/VNAV.
local FMC = {}
FMC.__index = FMC

local MAX_WAYPOINTS = 64
local MAX_IDENT = 8
local function ident(v)
	local s = string.upper(string.sub(tostring(v or ""), 1, MAX_IDENT))
	return s:match("^[A-Z0-9%-%._]+$") and s or ""
end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end

local function copyWaypoint(w)
	if type(w)~="table" or typeof(w.Position)~="Vector3" then return nil end
	local p=w.Position
	local alt=w.Altitude
	if alt~=nil and (not finite(tonumber(alt)) or alt<0 or alt>60000) then return nil end
	return {Ident=ident(w.Ident),Position=p,Altitude=alt and tonumber(alt) or nil,CaptureRadius=math.clamp(tonumber(w.CaptureRadius) or 2500,250,10000)}
end

function FMC.new(state) return setmetatable({state=state,page="IDENT",scratch=""},FMC) end

function FMC:Step(dt)
	local x=self.state:Get()
	x.FMC=x.FMC or {Page=self.page,Scratchpad=self.scratch,Origin="",Destination="",CruiseAltitude=nil,Route={},Active=false}
	x.FMC.Page=x.FMC.Page or self.page
	x.FMC.Scratchpad=x.FMC.Scratchpad or self.scratch
end

function FMC:SetPage(page)
	local p=string.upper(string.sub(tostring(page or "IDENT"),1,16))
	local allowed={IDENT=true,RTE=true,LEGS=true,DEPARR=true,PERF=true,PROG=true,NAVRAD=true}
	if not allowed[p] then return false,"invalid_page" end
	local x=self.state:Get(); x.FMC=x.FMC or {}; x.FMC.Page=p; self.page=p; return true
end

function FMC:SetScratchpad(text)
	local x=self.state:Get(); x.FMC=x.FMC or {}
	x.FMC.Scratchpad=string.upper(string.sub(tostring(text or ""),1,80)); self.scratch=x.FMC.Scratchpad
	return true
end

function FMC:SetRoute(origin,destination,route,cruiseAltitude)
	if type(route)~="table" or #route>MAX_WAYPOINTS then return false,"invalid_route" end
	local o,d=ident(origin),ident(destination)
	if o=="" or d=="" then return false,"invalid_airport" end
	local ca=tonumber(cruiseAltitude)
	if ca and (not finite(ca) or ca<0 or ca>60000) then return false,"invalid_cruise_altitude" end
	local clean={}
	for i=1,#route do
		local w=copyWaypoint(route[i]); if not w then return false,"invalid_waypoint_"..i end; clean[i]=w
	end
	local x=self.state:Get(); x.FMC=x.FMC or {}
	x.FMC.Origin=o; x.FMC.Destination=d; x.FMC.Route=clean; x.FMC.CruiseAltitude=ca; x.FMC.Active=#clean>0
	x.Navigation.Route=clean; x.Navigation.ActiveWaypoint=1; x.Navigation.RouteComplete=false
	return true
end

return FMC
