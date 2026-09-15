--!strict
-- Roblox Flight Simulator bootstrap
-- This is the first source artifact. It creates the core simulation container
-- inside ReplicatedStorage/ServerScriptService and seeds the authoritative
-- aircraft state model. Systems are intentionally modular so the final
-- simulator does not become one unmaintainable monolithic script.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ROOT_NAME = "FlightSim"
local VERSION = "0.1.0-foundation"

local root = ReplicatedStorage:FindFirstChild(ROOT_NAME)
if root then
	root:Destroy()
end
root = Instance.new("Folder")
root.Name = ROOT_NAME
root.Parent = ReplicatedStorage

local shared = Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = root

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = root

local serverRoot = ServerScriptService:FindFirstChild(ROOT_NAME)
if serverRoot then
	serverRoot:Destroy()
end
serverRoot = Instance.new("Folder")
serverRoot.Name = ROOT_NAME
serverRoot.Parent = ServerScriptService

local systems = Instance.new("Folder")
systems.Name = "Systems"
systems.Parent = serverRoot

local function makeModule(parent: Instance, name: string, source: string)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = source
	m.Parent = parent
	return m
end

makeModule(shared, "Config", [[
local Config = {
	Version = "0.1.0-foundation",
	Aircraft = "B737-800",
	ServerAuthoritative = true,
	Units = {Altitude = "ft", Speed = "kt", Distance = "nm", Fuel = "kg"},
}
return Config
]])

makeModule(shared, "Signal", [[
local Signal = {}
Signal.__index = Signal
function Signal.new()
	return setmetatable({listeners = {}}, Signal)
end
function Signal:Connect(fn)
	table.insert(self.listeners, fn)
	local alive = true
	return {Disconnect = function()
		if not alive then return end
		alive = false
		for i, cb in ipairs(self.listeners) do
			if cb == fn then table.remove(self.listeners, i) break end
		end
	end}
end
function Signal:Fire(...)
	for _, fn in ipairs(self.listeners) do task.spawn(fn, ...) end
end
return Signal
]])

makeModule(systems, "AircraftState", [[
local AircraftState = {}
AircraftState.__index = AircraftState

function AircraftState.new()
	local self = setmetatable({}, AircraftState)
	self.data = {
		Phase = "ColdAndDark",
		Position = Vector3.zero,
		Velocity = Vector3.zero,
		Altitude = 0,
		Airspeed = 0,
		Heading = 0,
		Pitch = 0,
		Roll = 0,
		Yaw = 0,
		Engines = {
			[1] = {N1=0,N2=0,EGT=0,FuelFlow=0,OilPressure=0,Running=false},
			[2] = {N1=0,N2=0,EGT=0,FuelFlow=0,OilPressure=0,Running=false},
		},
		Electrical = {Battery=false,ExternalPower=false,APU=false,Bus1=false,Bus2=false},
		Hydraulic = {A=0,B=0,Standby=0},
		Fuel = {Left=0,Center=0,Right=0,Total=0},
		FlightControls = {Aileron=0,Elevator=0,Rudder=0,Spoiler=0,Flap=0,Trim=0},
		Gear = {Nose=true,Left=true,Right=true},
		Brakes = {Parking=true,AutoBrake="RTO"},
		Avionics = {IRS=false,FMC=false,Radios=false,Transponder=false,TCAS=false},
		Autopilot = {Enabled=false,Mode="OFF",TargetAltitude=0,TargetHeading=0,TargetSpeed=0},
		Pressurization = {CabinAltitude=0,Differential=0},
		Failures = {},
	}
	return self
end

function AircraftState:Set(path, value)
	local node = self.data
	for i = 1, #path - 1 do
		node = node[path[i]]
		if node == nil then error("Invalid state path") end
	end
	node[path[#path]] = value
end

function AircraftState:Get()
	return self.data
end

return AircraftState
]])

local bootstrap = Instance.new("Script")
bootstrap.Name = "FlightSimBootstrap"
bootstrap.Source = [[
-- Server bootstrap placeholder. System modules are added incrementally by the project build.
local ServerScriptService = game:GetService("ServerScriptService")
local root = ServerScriptService:WaitForChild("FlightSim")
local systems = root:WaitForChild("Systems")
local AircraftState = require(systems:WaitForChild("AircraftState"))
local state = AircraftState.new()
print("[FlightSim] foundation online")
print("[FlightSim] phase:", state:Get().Phase)
]]
bootstrap.Parent = serverRoot

local remote = Instance.new("RemoteEvent")
remote.Name = "AircraftCommand"
remote.Parent = remotes

print("[FlightSim] Installed " .. VERSION)
