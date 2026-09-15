-- FlightSim client: cockpit/input + instrument display layer
-- Place this LocalScript in StarterPlayerScripts.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("FlightSim"):WaitForChild("Remotes")
local command = remotes:WaitForChild("AircraftCommand")
local telemetry = remotes:WaitForChild("Telemetry")

local gui = Instance.new("ScreenGui")
gui.Name = "FlightSimInstruments"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "PFD"
panel.Size = UDim2.fromOffset(330, 250)
panel.Position = UDim2.new(0, 18, 1, -268)
panel.BackgroundTransparency = 0.12
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "B737-800  •  FLIGHT DECK"
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local readout = Instance.new("TextLabel")
readout.Name = "Readout"
readout.Position = UDim2.fromOffset(12, 36)
readout.Size = UDim2.new(1, -24, 1, -48)
readout.BackgroundTransparency = 1
readout.TextSize = 16
readout.Font = Enum.Font.Code
readout.TextXAlignment = Enum.TextXAlignment.Left
readout.TextYAlignment = Enum.TextYAlignment.Top
readout.Text = "WAITING FOR SIMULATION..."
readout.Parent = panel

local help = Instance.new("TextLabel")
help.Size = UDim2.new(0, 500, 0, 72)
help.Position = UDim2.new(1, -518, 1, -90)
help.BackgroundTransparency = 0.18
help.TextSize = 14
help.Font = Enum.Font.Gotham
help.TextXAlignment = Enum.TextXAlignment.Left
help.TextYAlignment = Enum.TextYAlignment.Top
help.Text = "INPUT\nW/S = elevator   A/D = aileron   Q/E = rudder\nF = flap toggle   G = landing gear   B = parking brake\n1/2 = engine starter   R/T = engine fuel   Y/U = ignition\nP = battery   O = APU   L = autopilot"
help.Parent = gui

local latest
local flap = 0
local gearDown = true
local parkingBrake = true
local battery = false
local apu = false
local ap = false
local starter = {[1]=false,[2]=false}
local fuel = {[1]=false,[2]=false}
local ignition = {[1]=false,[2]=false}

local function send(name, a, b)
	command:FireServer(name, a, b)
end

local function updateControls()
	if UserInputService:GetFocusedTextBox() then return end
	local elevator, aileron, rudder = 0, 0, 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then elevator += 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then elevator -= 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then aileron += 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then aileron -= 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then rudder += 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then rudder -= 1 end
	send("Control", "Elevator", elevator)
	send("Control", "Aileron", aileron)
	send("Control", "Rudder", rudder)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.P then
		battery = not battery; send("Battery", battery)
	elseif k == Enum.KeyCode.O then
		apu = not apu; send("APU", apu)
	elseif k == Enum.KeyCode.L then
		ap = not ap; send("AP", ap)
	elseif k == Enum.KeyCode.F then
		flap = (flap == 0) and 0.5 or ((flap == 0.5) and 1 or 0); send("Flap", flap)
	elseif k == Enum.KeyCode.G then
		gearDown = not gearDown; send("Gear", gearDown)
	elseif k == Enum.KeyCode.B then
		parkingBrake = not parkingBrake; send("ParkingBrake", parkingBrake)
	elseif k == Enum.KeyCode.One then
		starter[1] = not starter[1]; send("EngineStarter", 1, starter[1])
	elseif k == Enum.KeyCode.Two then
		starter[2] = not starter[2]; send("EngineStarter", 2, starter[2])
	elseif k == Enum.KeyCode.R then
		fuel[1] = not fuel[1]; send("EngineFuel", 1, fuel[1])
	elseif k == Enum.KeyCode.T then
		fuel[2] = not fuel[2]; send("EngineFuel", 2, fuel[2])
	elseif k == Enum.KeyCode.Y then
		ignition[1] = not ignition[1]; send("EngineIgnition", 1, ignition[1])
	elseif k == Enum.KeyCode.U then
		ignition[2] = not ignition[2]; send("EngineIgnition", 2, ignition[2])
	end
end)

telemetry.OnClientEvent:Connect(function(state)
	latest = state
	local e1, e2 = state.Engines[1], state.Engines[2]
	readout.Text = string.format(
		"PHASE  %-14s\nALT    %7.0f ft     IAS %5.0f kt\nHDG    %7.1f°      P/R %4.1f/%4.1f°\n\nENG 1  N1 %5.1f%%  N2 %5.1f%%  EGT %4.0f\n       OIL %5.1f%%  FF %6.0f  RUN %s\nENG 2  N1 %5.1f%%  N2 %5.1f%%  EGT %4.0f\n       OIL %5.1f%%  FF %6.0f  RUN %s\n\nELEC   BAT %s  APU %s  BUS %s/%s\nHYD    A %4.0f psi   B %4.0f psi\nFUEL   %7.0f / 30000\nGEAR   %s       FLAP %.0f%%     BRK %s\nAP     %s  ALT %6.0f  HDG %6.1f",
		state.Phase, state.Altitude, state.Airspeed, state.Heading, state.Pitch, state.Roll,
		e1.N1, e1.N2, e1.EGT, e1.OilPressure, e1.FuelFlow, tostring(e1.Running),
		e2.N1, e2.N2, e2.EGT, e2.OilPressure, e2.FuelFlow, tostring(e2.Running),
		tostring(state.Electrical.Battery), tostring(state.Electrical.APU), tostring(state.Electrical.Bus1), tostring(state.Electrical.Bus2),
		state.Hydraulic.A, state.Hydraulic.B, state.Fuel.Total,
		state.Gear.Nose and "DOWN" or "UP", state.Controls.Flap * 100, state.Brakes.Parking and "SET" or "OFF",
		tostring(state.Autopilot.Enabled), state.Autopilot.TargetAltitude, state.Autopilot.TargetHeading
	)
end)

RunService.RenderStepped:Connect(updateControls)
