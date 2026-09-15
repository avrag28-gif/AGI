-- FlightSim multi-aircraft simulation orchestrator v0.2
local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(registry, modules)
	return setmetatable({registry = registry, modules = modules, aircraft = {}}, Simulation)
end

function Simulation:AddAircraft(id, state)
	local systems = {
		electrical = self.modules.Electrical.new(state),
		engine = self.modules.Engine.new(state),
		core = self.modules.Core.new(state),
		physics = self.modules.Physics.new(state),
	}
	self.aircraft[id] = systems
	return systems
end

function Simulation:RemoveAircraft(id)
	self.aircraft[id] = nil
end

function Simulation:Step(dt)
	self.registry:ForEach(function(id, state)
		local systems = self.aircraft[id]
		if not systems then
			systems = self:AddAircraft(id, state)
		end

		-- Electrical establishes bus availability before engine operation.
		systems.electrical:Step(dt)
		systems.engine:Step(dt)
		systems.electrical:Step(dt)
		systems.core:Step(dt)
		systems.physics:Step(dt)
	end)
end

return Simulation
