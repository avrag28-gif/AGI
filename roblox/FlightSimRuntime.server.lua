-- FlightSim modular runtime v0.5
-- Server-authoritative simulation entry point.
-- Static ModuleScripts are expected under script.Parent/FlightSimSystems.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
local systemsFolder = root:WaitForChild("FlightSimSystems")
local shared = ReplicatedStorage:WaitForChild("FlightSim")
local remotes = shared:WaitForChild("Remotes")

local Config = require(systemsFolder:WaitForChild("Config"))
local State = require(systemsFolder:WaitForChild("State"))
local Electrical = require(systemsFolder:WaitForChild("Electrical"))
local Engine = require(systemsFolder:WaitForChild("Engine"))
local Core = require(systemsFolder:WaitForChild("Core"))
local FlightControls = require(systemsFolder:WaitForChild("FlightControls"))
local LandingGear = require(systemsFolder:WaitForChild("LandingGear"))
local Brakes = require(systemsFolder:WaitForChild("Brakes"))
local Avionics = require(systemsFolder:WaitForChild("Avionics"))
local Navigation = require(systemsFolder:WaitForChild("Navigation"))
local WaypointManager = require(systemsFolder:WaitForChild("WaypointManager"))
local Autopilot = require(systemsFolder:WaitForChild("Autopilot"))
local VNAV = require(systemsFolder:WaitForChild("VNAV"))
local FMC = require(systemsFolder:WaitForChild("FMC"))
local Physics = require(systemsFolder:WaitForChild("Physics"))
local AircraftRegistry = require(systemsFolder:WaitForChild("AircraftRegistry"))
local CommandRouter = require(systemsFolder:WaitForChild("CommandRouter"))

local registry = AircraftRegistry.new()
local router = CommandRouter.new(registry)
local simulations = {}

local function createAircraftForPlayer(player)
	local id = "P_" .. tostring(player.UserId)
	if registry:Get(id) then return end

	local state = State.new()
	registry:Register(id, state, player)
	simulations[id] = {
		state = state,
		electrical = Electrical.new(state), engine = Engine.new(state), core = Core.new(state),
		flightControls = FlightControls.new(state), landingGear = LandingGear.new(state),
		brakes = Brakes.new(state), avionics = Avionics.new(state), navigation = Navigation.new(state),
		waypoints = WaypointManager.new(state), autopilot = Autopilot.new(state),
		vnav = VNAV.new(state), fmc = FMC.new(state), physics = Physics.new(state),
	}
end

local function removeAircraftForPlayer(player)
	local id = "P_" .. tostring(player.UserId)
	registry:Unregister(id)
	simulations[id] = nil
end

Players.PlayerAdded:Connect(createAircraftForPlayer)
Players.PlayerRemoving:Connect(removeAircraftForPlayer)
for _, player in Players:GetPlayers() do createAircraftForPlayer(player) end

local commandRemote = remotes:FindFirstChild("AircraftCommand")
if commandRemote then
	commandRemote.OnServerEvent:Connect(function(player, command, a, b)
		local id = registry:GetForPlayer(player)
		if not id then return end
		local ok, reason = router:Handle(player, id, command, a, b)
		if not ok then warn("[FlightSim] rejected command", player.Name, reason) end
	end)
end

local accumulator, telemetryAccumulator = 0, 0
local fixedStep = 1 / (tonumber(Config.SimulationRate) or 60)

local function simulationStep(dt)
	registry:ForEach(function(id)
		local sim = simulations[id]
		if not sim then return end
		sim.electrical:Step(dt)
		sim.engine:Step(dt)
		sim.electrical:Step(dt)
		sim.core:Step(dt)
		sim.fmc:Step(dt)
		sim.waypoints:Step(dt)
		sim.navigation:Step(dt)
		sim.vnav:Step(dt)
		sim.autopilot:Step(dt)
		sim.flightControls:Step(dt)
		sim.landingGear:Step(dt)
		sim.brakes:Step(dt)
		sim.avionics:Step(dt)
		sim.physics:Step(dt)
	end)
end

RunService.Heartbeat:Connect(function(frameDt)
	frameDt = math.min(frameDt, 0.25)
	accumulator += frameDt
	while accumulator >= fixedStep do
		simulationStep(fixedStep)
		accumulator -= fixedStep
	end

	telemetryAccumulator += frameDt
	if telemetryAccumulator >= 1 / (tonumber(Config.TelemetryRate) or 20) then
		telemetryAccumulator = 0
		local telemetry = remotes:FindFirstChild("Telemetry")
		if telemetry then
			registry:ForEach(function(_, state, owner)
				if owner then telemetry:FireClient(owner, state:Get()) end
			end)
		end
	end
end)

print("[FlightSim] Modular runtime online", Config.Aircraft or "Unknown aircraft")
