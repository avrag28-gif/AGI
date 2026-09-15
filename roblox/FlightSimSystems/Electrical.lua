-- FlightSim electrical system v0.2
local Electrical = {}
Electrical.__index = Electrical

function Electrical.new(state)
	return setmetatable({state = state}, Electrical)
end

function Electrical:Step(dt)
	local x = self.state:Get()
	local e = x.Electrical
	local eng1 = x.Engines[1]
	local eng2 = x.Engines[2]

	-- Source availability. Battery is a backup source; external/APU/engine
	-- generators take priority for normal aircraft buses.
	local source1 = e.ExternalPower or e.APU or eng1.GeneratorAvailable or e.Battery
	local source2 = e.ExternalPower or e.APU or eng2.GeneratorAvailable or e.Battery

	e.Bus1 = source1
	e.Bus2 = source2

	if e.Battery and not (e.ExternalPower or e.APU or eng1.GeneratorAvailable or eng2.GeneratorAvailable) then
		-- Battery reserve is represented as a normalized charge in State.
		x.BatteryCharge = math.max(0, (x.BatteryCharge or 1) - 0.002 * dt)
		if x.BatteryCharge <= 0 then
			e.Battery = false
		end
	elseif e.Battery then
		x.BatteryCharge = math.min(1, (x.BatteryCharge or 1) + 0.0005 * dt)
	end
end

return Electrical
