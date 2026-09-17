-- Fuel mass normalization for the 737-800 simulation.
-- Boeing public airport-planning data gives usable fuel as 20,897 kg.
-- Tank quantities in State/Fuel are kilograms in this simulation.
local FuelMassBalance = {}

local function finite(v, fallback)
	v = tonumber(v)
	if v and v == v and v ~= math.huge and v ~= -math.huge then
		return v
	end
	return fallback
end

function FuelMassBalance.Calculate(state, profile)
	local fuel = state and state.Fuel or {}
	local weights = profile and profile.Weights or {}
	local total = math.max(0, finite(fuel.Total, 0))
	local maxUsable = math.max(0, finite(weights.MaxUsableFuelMassKg, 20897))
	local mass = math.min(total, maxUsable)
	return {
		MassKg = mass,
		ReportedMassKg = total,
		MaxUsableMassKg = maxUsable,
		OverCapacity = total > maxUsable,
		Fraction = maxUsable > 0 and mass / maxUsable or 0,
	}
end

return FuelMassBalance
