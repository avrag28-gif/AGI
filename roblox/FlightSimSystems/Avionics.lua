-- FlightSim avionics foundation v0.1
local Avionics = {}
Avionics.__index = Avionics

function Avionics.new(state)
	return setmetatable({state = state}, Avionics)
end

function Avionics:Step(dt)
	local x = self.state:Get()
	local powered = x.Electrical.Bus1 or x.Electrical.Bus2
	local a = x.Avionics

	a.IRS = powered
	a.FMC = powered
	a.Radios = powered
	a.Transponder = powered
	a.TCAS = powered
	a.WeatherRadar = powered and (x.WeatherRadarEnabled ~= false) or false
end

return Avionics
