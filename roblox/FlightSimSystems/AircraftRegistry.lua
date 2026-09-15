-- FlightSim aircraft registry v0.1
-- Server-owned registry. One authoritative simulation state per aircraft.
local AircraftRegistry = {}
AircraftRegistry.__index = AircraftRegistry

function AircraftRegistry.new()
	return setmetatable({aircraft = {}, owners = {}}, AircraftRegistry)
end

function AircraftRegistry:Register(id, state, owner)
	assert(id ~= nil, "aircraft id required")
	assert(state ~= nil, "aircraft state required")
	self.aircraft[id] = state
	if owner then
		self.owners[id] = owner
	end
	return state
end

function AircraftRegistry:Unregister(id)
	self.aircraft[id] = nil
	self.owners[id] = nil
end

function AircraftRegistry:Get(id)
	return self.aircraft[id]
end

function AircraftRegistry:GetOwner(id)
	return self.owners[id]
end

function AircraftRegistry:SetOwner(id, owner)
	if self.aircraft[id] then
		self.owners[id] = owner
		return true
	end
	return false
end

function AircraftRegistry:GetForPlayer(player)
	for id, owner in pairs(self.owners) do
		if owner == player then
			return id, self.aircraft[id]
		end
	end
	return nil, nil
end

function AircraftRegistry:ForEach(callback)
	for id, state in pairs(self.aircraft) do
		callback(id, state, self.owners[id])
	end
end

return AircraftRegistry
