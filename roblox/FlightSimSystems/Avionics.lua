-- FlightSim avionics foundation v0.3
-- Electrical-dependent avionics state. Physical electrical failures are owned by Electrical/Failures.
local Avionics = {}
Avionics.__index = Avionics

function Avionics.new(state)
	return setmetatable({state = state}, Avionics)
end

function Avionics:Step(dt)
	local x = self.state:Get()
	local electrical = x.Electrical or {}
	local e = x.ElectricalState or {}
	local a = x.Avionics or {}
	local bus1 = electrical.Bus1 == true
	local bus2 = electrical.Bus2 == true
	local powered = bus1 or bus2
	local displayShed = e.LoadShed and e.LoadShed.Display == true
	local avionicsShed = e.LoadShed and e.LoadShed.Avionics == true

	a.IRS = powered and not avionicsShed
	a.FMC = powered and not avionicsShed
	a.Radios = powered and not avionicsShed
	a.Transponder = powered and not avionicsShed
	a.TCAS = powered and not avionicsShed
	a.WeatherRadar = powered and not avionicsShed and not displayShed and a.WeatherRadarEnabled ~= false

	x.Avionics = a
end

return Avionics
