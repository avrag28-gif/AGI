-- FlightSim engine runtime module v0.3
local Config = require(script.Parent.Config)
local Engine = {}
Engine.__index = Engine

function Engine.new(state)
	return setmetatable({state = state}, Engine)
end

function Engine:Step(dt)
	local x = self.state:Get()
	for index, e in pairs(x.Engines) do
		local electrical = x.Electrical.Bus1 or x.Electrical.Bus2
		if e.Starter and electrical then
			e.N2 = math.min(60, e.N2 + 18 * dt)
		else
			e.N2 = math.max(0, e.N2 - 3 * dt)
		end

		if e.Starter and e.FuelOn and e.Ignition and e.N2 >= Config.StartN2 then
			e.Running = true
		e.StartFailed = false
		end

		if not e.FuelOn or x.Fuel.Total <= 0 then
			e.Running = false
		end

		if e.Running then
			local throttle = math.clamp(x.Throttle[index] or 0, 0, 1)
			local targetN1 = 20 + throttle * 80
			e.N1 += (targetN1 - e.N1) * math.min(1, 0.8 * dt)
			e.N2 += ((55 + throttle * 35) - e.N2) * math.min(1, 0.5 * dt)
			e.EGT = math.clamp(e.EGT + (350 + throttle * 300 - e.EGT) * math.min(1, 1.1 * dt), 20, 910)
			e.OilPressure = math.clamp(e.OilPressure + (80 + throttle * 10 - e.OilPressure) * math.min(1, 1.2 * dt), 0, 100)
			e.FuelFlow = e.N1 * 24
			e.Thrust = e.N1 / 100 * Config.MaxThrust / 2
			e.GeneratorAvailable = e.N2 >= 50
		else
			e.N1 = math.max(0, e.N1 - 18 * dt)
			e.EGT = math.max(20, e.EGT - 90 * dt)
			e.OilPressure = math.max(0, e.OilPressure - 30 * dt)
			e.FuelFlow = 0
			e.Thrust = 0
			e.GeneratorAvailable = false
		end
	end
end

return Engine
