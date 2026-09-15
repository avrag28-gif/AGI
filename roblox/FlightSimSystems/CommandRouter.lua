-- FlightSim server command router v0.1
-- Never trusts client-provided aircraft ownership or arbitrary state mutation.
local CommandRouter = {}
CommandRouter.__index = CommandRouter

local ALLOWED = {
	Battery = true, ExternalPower = true, APU = true,
	EngineStarter = true, EngineFuel = true, EngineIgnition = true,
	Throttle = true, Control = true, Flap = true, Gear = true,
	ParkingBrake = true, AP = true, APTarget = true,
}

function CommandRouter.new(registry)
	return setmetatable({registry = registry, lastCommand = {}}, CommandRouter)
end

function CommandRouter:_allowed(player, aircraftId)
	local owner = self.registry:GetOwner(aircraftId)
	return owner == player
end

function CommandRouter:Handle(player, aircraftId, command, a, b)
	if type(command) ~= "string" or not ALLOWED[command] then
		return false, "command_not_allowed"
	end
	if not self:_allowed(player, aircraftId) then
		return false, "aircraft_not_owned"
	end

	local state = self.registry:Get(aircraftId)
	if not state then
		return false, "aircraft_not_found"
	end

	local x = state:Get()
	if command == "Battery" then
		x.Electrical.Battery = a == true
	elseif command == "ExternalPower" then
		x.Electrical.ExternalPower = a == true
	elseif command == "APU" then
		x.Electrical.APU = a == true
	elseif command == "EngineStarter" or command == "EngineFuel" or command == "EngineIgnition" then
		local index = math.clamp(tonumber(a) or 0, 1, 2)
		local engine = x.Engines[index]
		if command == "EngineStarter" then engine.Starter = b == true end
		if command == "EngineFuel" then engine.FuelOn = b == true end
		if command == "EngineIgnition" then engine.Ignition = b == true end
	elseif command == "Throttle" then
		local index = math.clamp(tonumber(a) or 0, 1, 2)
		x.Throttle[index] = math.clamp(tonumber(b) or 0, 0, 1)
	elseif command == "Control" then
		local axis = tostring(a)
		if x.Controls[axis] ~= nil then x.Controls[axis] = math.clamp(tonumber(b) or 0, -1, 1) end
	elseif command == "Flap" then
		x.Controls.Flap = math.clamp(tonumber(a) or 0, 0, 1)
	elseif command == "Gear" then
		local down = a == true
		x.Gear.Nose, x.Gear.Left, x.Gear.Right = down, down, down
	elseif command == "ParkingBrake" then
		x.Brakes.Parking = a == true
	elseif command == "AP" then
		x.Autopilot.Enabled = a == true
	elseif command == "APTarget" then
		x.Autopilot.TargetAltitude = math.max(0, tonumber(a) or x.Autopilot.TargetAltitude)
		x.Autopilot.TargetHeading = (tonumber(b) or x.Autopilot.TargetHeading) % 360
	end
	return true
end

return CommandRouter
