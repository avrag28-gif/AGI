-- FlightSim aircraft core systems integration v0.3
local Config = require(script.Parent.Config)
local Core = {}
Core.__index = Core

function Core.new(state)
	return setmetatable({state = state}, Core)
end

function Core:Step(dt)
	local x = self.state:Get()
	local e = x.Electrical
	local engine1 = x.Engines[1]
	local engine2 = x.Engines[2]

	-- Generator availability is produced by the engine subsystem. APU/external
	-- power remain independent sources until their dedicated models mature.
	e.Bus1 = e.Battery or e.ExternalPower or e.APU or engine1.GeneratorAvailable
	e.Bus2 = e.Battery or e.ExternalPower or e.APU or engine2.GeneratorAvailable

	local hydraulicSource = engine1.Running or engine2.Running
	local hydraulicRate = hydraulicSource and 900 or -450
	x.Hydraulic.A = math.clamp(x.Hydraulic.A + hydraulicRate * dt, 0, Config.HydraulicMax)
	x.Hydraulic.B = math.clamp(x.Hydraulic.B + hydraulicRate * dt, 0, Config.HydraulicMax)

	local powered = e.Bus1 or e.Bus2
	x.Avionics.IRS = powered
	x.Avionics.FMC = powered
	x.Avionics.Radios = powered
	x.Avionics.Transponder = powered
	x.Avionics.TCAS = powered

	local totalFlow = 0
	for _, engine in pairs(x.Engines) do
		if engine.Running and engine.FuelOn then
			totalFlow += math.max(0, engine.FuelFlow)
		end
	end

	if totalFlow > 0 and x.Fuel.Total > 0 then
		local consumed = totalFlow * dt / 60
		local center = math.min(x.Fuel.Center, consumed)
		x.Fuel.Center -= center
		consumed -= center
		if consumed > 0 then
			local wingTotal = x.Fuel.Left + x.Fuel.Right
			if wingTotal > 0 then
				local leftShare = consumed * x.Fuel.Left / wingTotal
				local rightShare = consumed - leftShare
				x.Fuel.Left = math.max(0, x.Fuel.Left - leftShare)
				x.Fuel.Right = math.max(0, x.Fuel.Right - rightShare)
			end
		end
	end

	x.Fuel.Total = math.max(0, x.Fuel.Left + x.Fuel.Center + x.Fuel.Right)
end

return Core
