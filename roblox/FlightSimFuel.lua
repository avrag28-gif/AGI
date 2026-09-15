-- FlightSim Fuel System v0.1
-- Modular source. Not yet wired into the legacy bootstrap.
-- Internal fuel quantity is normalized to 0..1 per tank; capacity is configurable.

local Fuel = {}
Fuel.__index = Fuel

local DEFAULTS = {
	LeftCapacity = 1000,
	CenterCapacity = 500,
	RightCapacity = 1000,
	Left = 1000,
	Center = 500,
	Right = 1000,
	TransferRate = 200,
	BurnEnabled = true,
}

local function clampNonNegative(v)
	return math.max(0, tonumber(v) or 0)
end

function Fuel.new()
	return setmetatable({
		state = {
			LeftCapacity = DEFAULTS.LeftCapacity,
			CenterCapacity = DEFAULTS.CenterCapacity,
			RightCapacity = DEFAULTS.RightCapacity,
			Left = DEFAULTS.Left,
			Center = DEFAULTS.Center,
			Right = DEFAULTS.Right,
			TransferRate = DEFAULTS.TransferRate,
			BurnEnabled = DEFAULTS.BurnEnabled,
			Total = DEFAULTS.Left + DEFAULTS.Center + DEFAULTS.Right,
			LowFuel = false,
		},
	}, Fuel)
end

function Fuel:GetState()
	return self.state
end

function Fuel:SetTank(name, quantity)
	local capacity = self.state[name .. "Capacity"]
	if not capacity then return false end
	self.state[name] = math.clamp(clampNonNegative(quantity), 0, capacity)
	self:_recalculate()
	return true
end

function Fuel:SetBurnEnabled(enabled)
	self.state.BurnEnabled = enabled == true
end

function Fuel:_recalculate()
	local s = self.state
	s.Total = s.Left + s.Center + s.Right
	s.LowFuel = s.Total <= 0.15 * (s.LeftCapacity + s.CenterCapacity + s.RightCapacity)
end

-- Draw fuel from the center tank first, then wing tanks.
-- `rate` is total fuel units per second.
function Fuel:Consume(rate, dt)
	if not self.state.BurnEnabled then return 0 end
	if type(rate) ~= "number" or rate <= 0 or type(dt) ~= "number" or dt <= 0 then return 0 end

	local requested = rate * dt
	local consumed = 0

	local centerDraw = math.min(self.state.Center, requested)
	self.state.Center -= centerDraw
	requested -= centerDraw
	consumed += centerDraw

	if requested > 0 then
		local wingTotal = self.state.Left + self.state.Right
		if wingTotal > 0 then
			local leftShare = requested * (self.state.Left / wingTotal)
			local rightShare = requested - leftShare
			local leftDraw = math.min(self.state.Left, leftShare)
			local rightDraw = math.min(self.state.Right, rightShare)
			self.state.Left -= leftDraw
			self.state.Right -= rightDraw
			consumed += leftDraw + rightDraw
		end
	end

	self:_recalculate()
	return consumed
end

function Fuel:Step(dt, engineFuelFlow)
	local flow = clampNonNegative(engineFuelFlow)
	self:Consume(flow, dt)
	self:_recalculate()
	return self.state
end

return Fuel
