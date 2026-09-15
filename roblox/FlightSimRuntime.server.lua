-- FlightSim modular runtime v0.1
-- Production-direction runtime entry point. Requires the modular source files
-- to be installed as sibling ModuleScripts under a FlightSim/System hierarchy.
-- This file intentionally does not use ModuleScript.Source at runtime.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
local systemsFolder = root:WaitForChild("Systems")
local shared = ReplicatedStorage:WaitForChild("FlightSim")
local remotes = shared:WaitForChild("Remotes")

local Config = require(systemsFolder:WaitForChild("Config"))
local State = require(systemsFolder:WaitForChild("State"))
local Engine = require(systemsFolder:WaitForChild("Engine"))
local Core = require(systemsFolder:WaitForChild("Core"))
local Physics = require(systemsFolder:WaitForChild("Physics"))

local state = State.new()
local engine = Engine.new(state)
local core = Core.new(state)
local physics = Physics.new(state)

local accumulator = 0
local telemetryAccumulator = 0
local fixedStep = 1 / 60

local function simulationStep(dt)
	-- Keep the order deterministic: power/fuel availability first, then engine,
	-- aircraft systems, and finally flight dynamics.
	engine:Step(dt)
	core:Step(dt)
	physics:Step(dt)
end

RunService.Heartbeat:Connect(function(frameDt)
	frameDt = math.min(frameDt, 0.25)
	accumulator += frameDt

	while accumulator >= fixedStep do
		simulationStep(fixedStep)
		accumulator -= fixedStep
	end

	telemetryAccumulator += frameDt
	local rate = tonumber(Config.TelemetryRate) or 20
	if telemetryAccumulator >= 1 / rate then
		telemetryAccumulator = 0
		local telemetry = remotes:FindFirstChild("Telemetry")
		if telemetry then
			telemetry:FireAllClients(state:Get())
		end
	end
end)

print("[FlightSim] Modular runtime online", Config.Aircraft or "Unknown aircraft")
