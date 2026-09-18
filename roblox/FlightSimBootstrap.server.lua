-- FlightSim bootstrap v1.0
-- Safe Studio installer for the modular runtime.
-- This script deliberately does NOT embed or overwrite simulation modules.
-- Place this Script in ServerScriptService and run once in Studio.
local RS=game:GetService("ReplicatedStorage")
local shared=RS:FindFirstChild("FlightSim")
if not shared then
	shared=Instance.new("Folder")
	shared.Name="FlightSim"
	shared.Parent=RS
end

local remotes=shared:FindFirstChild("Remotes")
if not remotes then
	remotes=Instance.new("Folder")
	remotes.Name="Remotes"
	remotes.Parent=shared
end

local function ensureRemote(name)
	local r=remotes:FindFirstChild(name)
	if r and not r:IsA("RemoteEvent") then r:Destroy(); r=nil end
	if not r then
		r=Instance.new("RemoteEvent")
		r.Name=name
		r.Parent=remotes
	end
	return r
end

ensureRemote("AircraftCommand")
ensureRemote("Telemetry")

print("[FlightSim] v1.0 bootstrap ready: remotes preserved/created; modular runtime was not overwritten.")
print("[FlightSim] Required layout: ServerScriptService/FlightSimRuntime.server.lua + ServerScriptService/FlightSimSystems/*")
print("[FlightSim] Client: StarterPlayer/StarterPlayerScripts/FlightSimClient.client.lua")
