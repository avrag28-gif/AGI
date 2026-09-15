-- FlightSim FMC/CDU data model v0.1
-- UI-independent: CDU screens can be built on top of this state machine.
local FMC = {}
FMC.__index = FMC

local function cleanIdent(value)
	return string.upper(string.sub(tostring(value or ""), 1, 8))
end

function FMC.new(state)
	return setmetatable({state = state, scratch = "", page = "IDENT"}, FMC)
end

function FMC:Step(dt)
	local x = self.state:Get()
	x.FMC = x.FMC or {
		Page = self.page,
		Scratchpad = self.scratch,
		Origin = nil,
		Destination = nil,
		CruiseAltitude = nil,
		Route = {},
		Active = false,
	}
	self.page = x.FMC.Page or self.page
	self.scratch = x.FMC.Scratchpad or self.scratch
end

function FMC:SetScratchpad(text)
	local x = self.state:Get()
	x.FMC = x.FMC or {}
	x.FMC.Scratchpad = cleanIdent(text)
	self.scratch = x.FMC.Scratchpad
end

function FMC:SetRoute(origin, destination, route, cruiseAltitude)
	local x = self.state:Get()
	x.FMC = x.FMC or {}
	x.FMC.Origin = cleanIdent(origin)
	x.FMC.Destination = cleanIdent(destination)
	x.FMC.Route = route or {}
	x.FMC.CruiseAltitude = tonumber(cruiseAltitude)
	x.FMC.Active = #x.FMC.Route > 0
	x.Navigation.Route = x.FMC.Route
	x.Navigation.ActiveWaypoint = 1
end

return FMC
