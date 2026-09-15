-- FlightSim Electrical System v0.1
-- Source module for the modular migration. Not yet wired into the legacy bootstrap.
-- Units: voltage in volts, load in amps. Availability is boolean system state.

local Electrical = {}
Electrical.__index = Electrical

local DEFAULTS = {
	BatteryVoltage = 24,
	BatteryMinVoltage = 20,
	BatteryCapacityAh = 40,
	BatteryCharge = 1,
	ExternalPowerVoltage = 115,
	ExternalPowerAvailable = false,
	APUGeneratorAvailable = false,
	EngineGeneratorAvailable = {[1] = false, [2] = false},
	BusTie = true,
}

local function copyDefaults()
	local t = {}
	for k, v in pairs(DEFAULTS) do
		if type(v) == "table" then
			t[k] = {}
			for a, b in pairs(v) do t[k][a] = b end
		else
			t[k] = v
		end
	end
	return t
end

function Electrical.new()
	return setmetatable({state = copyDefaults()}, Electrical)
end

function Electrical:GetState()
	return self.state
end

function Electrical:SetExternalPower(connected)
	self.state.ExternalPowerAvailable = connected == true
end

function Electrical:SetAPUGeneratorAvailable(available)
	self.state.APUGeneratorAvailable = available == true
end

function Electrical:SetEngineGeneratorAvailable(engineIndex, available)
	if engineIndex ~= 1 and engineIndex ~= 2 then return false end
	self.state.EngineGeneratorAvailable[engineIndex] = available == true
	return true
end

function Electrical:SetBusTie(closed)
	self.state.BusTie = closed == true
end

function Electrical:SetBatteryCharge(fraction)
	self.state.BatteryCharge = math.clamp(tonumber(fraction) or 0, 0, 1)
end

-- Returns the currently available source for each AC-style bus.
-- This is intentionally a clean source-selection layer; load shedding and
-- detailed distribution will be added without changing the public interface.
function Electrical:EvaluateSources()
	local s = self.state
	local source = {
		Bus1 = "NONE",
		Bus2 = "NONE",
	}

	if s.ExternalPowerAvailable then
		source.Bus1 = "EXTERNAL"
		source.Bus2 = "EXTERNAL"
	elseif s.APUGeneratorAvailable then
		source.Bus1 = "APU"
		source.Bus2 = "APU"
	else
		if s.EngineGeneratorAvailable[1] then source.Bus1 = "GEN1" end
		if s.EngineGeneratorAvailable[2] then source.Bus2 = "GEN2" end
		if s.BusTie then
			if source.Bus1 == "NONE" and source.Bus2 ~= "NONE" then source.Bus1 = source.Bus2 end
			if source.Bus2 == "NONE" and source.Bus1 ~= "NONE" then source.Bus2 = source.Bus1 end
		end
	end

	return source
end

function Electrical:Step(dt)
	assert(type(dt) == "number" and dt >= 0, "Electrical:Step requires a non-negative dt")
	local s = self.state
	local source = self:EvaluateSources()

	s.Bus1Powered = source.Bus1 ~= "NONE"
	s.Bus2Powered = source.Bus2 ~= "NONE"

	-- Battery is modeled as a limited DC reserve for now. Detailed battery
	-- charging, TR units and load-shedding logic are intentionally deferred.
	local batteryLoad = 0
	if not s.Bus1Powered and not s.Bus2Powered then batteryLoad = 1 end
	if batteryLoad > 0 then
		s.BatteryCharge = math.max(0, s.BatteryCharge - dt / (DEFAULTS.BatteryCapacityAh * 3600))
	end

	s.BatteryVoltage = DEFAULTS.BatteryVoltage * (0.85 + 0.15 * s.BatteryCharge)
	s.BatteryAvailable = s.BatteryCharge > 0 and s.BatteryVoltage >= DEFAULTS.BatteryMinVoltage
	return s
end

return Electrical
