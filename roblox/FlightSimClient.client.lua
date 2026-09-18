-- FlightSim client: cockpit/input + instrument display layer v1.6
-- Place this LocalScript in StarterPlayerScripts.
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local remotes=game:GetService("ReplicatedStorage"):WaitForChild("FlightSim"):WaitForChild("Remotes")
local command=remotes:WaitForChild("AircraftCommand")
local telemetry=remotes:WaitForChild("Telemetry")

local gui=Instance.new("ScreenGui")
gui.Name="FlightSimInstruments"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")

local panel=Instance.new("Frame")
panel.Name="PFD"
panel.Size=UDim2.fromOffset(420,430)
panel.Position=UDim2.new(0,18,1,-448)
panel.BackgroundTransparency=0.12
panel.Parent=gui

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,0,0,30)
title.BackgroundTransparency=1
title.Text="B737-800  •  FLIGHT DECK"
title.TextSize=18
title.Font=Enum.Font.GothamBold
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=panel

local readout=Instance.new("TextLabel")
readout.Name="Readout"
readout.Position=UDim2.fromOffset(12,36)
readout.Size=UDim2.new(1,-24,1,-48)
readout.BackgroundTransparency=1
readout.TextSize=14
readout.Font=Enum.Font.Code
readout.TextXAlignment=Enum.TextXAlignment.Left
readout.TextYAlignment=Enum.TextYAlignment.Top
readout.Text="WAITING FOR SIMULATION..."
readout.Parent=panel

-- Instrument stack: compact PFD/ND/EICAS-style presentation using the authoritative telemetry payload.
-- If a physical cockpit SurfaceGui exists later, the same display formatting can be moved there.
local instruments=Instance.new("Frame")
instruments.Name="InstrumentStack"
instruments.Size=UDim2.fromOffset(560,310)
instruments.Position=UDim2.new(0,18,0,18)
instruments.BackgroundTransparency=0.18
instruments.Parent=gui

local pfd=Instance.new("TextLabel")
pfd.Name="PFD"
pfd.Size=UDim2.new(0.49,-6,1,0)
pfd.Position=UDim2.fromScale(0,0)
pfd.BackgroundTransparency=1
pfd.Font=Enum.Font.Code
pfd.TextSize=14
pfd.TextXAlignment=Enum.TextXAlignment.Left
pfd.TextYAlignment=Enum.TextYAlignment.Top
pfd.Text="PFD\nWAITING..."
pfd.Parent=instruments

local nd=Instance.new("TextLabel")
nd.Name="ND"
nd.Size=UDim2.new(0.49,-6,1,0)
nd.Position=UDim2.new(0.51,6,0,0)
nd.BackgroundTransparency=1
nd.Font=Enum.Font.Code
nd.TextSize=14
nd.TextXAlignment=Enum.TextXAlignment.Left
nd.TextYAlignment=Enum.TextYAlignment.Top
nd.Text="ND\nWAITING..."
nd.Parent=instruments

local eicas=Instance.new("TextLabel")
eicas.Name="EICAS"
eicas.Size=UDim2.fromOffset(420,180)
eicas.Position=UDim2.new(1,-438,0,18)
eicas.BackgroundTransparency=0.18
eicas.Font=Enum.Font.Code
eicas.TextSize=14
eicas.TextXAlignment=Enum.TextXAlignment.Left
eicas.TextYAlignment=Enum.TextYAlignment.Top
eicas.Text="EICAS\nWAITING..."
eicas.Parent=gui

local help=Instance.new("TextLabel")
help.Size=UDim2.new(0,650,0,175)
help.Position=UDim2.new(1,-668,1,-193)
help.BackgroundTransparency=0.18
help.TextSize=13
help.Font=Enum.Font.Gotham
help.TextXAlignment=Enum.TextXAlignment.Left
help.TextYAlignment=Enum.TextYAlignment.Top
help.Text="INPUT\nW/S elevator   A/D aileron   Q/E rudder   Z/C nose-wheel\nF flap   G gear   B parking brake   1/2 starter   R/T fuel   Y/U ignition\nP battery   O APU   L AP   J A/T   X TOGA/go-around\nM/N MCP speed -/+5   K/I MCP VS -/+250\nPageUp/PageDown or [/] throttle both engines\nTraffic display: TA/RA and ATC conflict state are shown when available."
help.Parent=gui

local flap=0
local gearDown=true
local parkingBrake=true
local battery=false
local apu=false
local ap=false
local autoThrottle=false
local mcpSpeed=250
local mcpVS=0
local throttle={[1]=0,[2]=0}
local throttleAccumulator=0
local starter={[1]=false,[2]=false}
local fuel={[1]=false,[2]=false}
local ignition={[1]=false,[2]=false}
local lastControl={Elevator=999,Aileron=999,Rudder=999,NoseWheelSteering=999}
local controlAccumulator=0

local function findPhysicalDisplay(names)
	local tagged=workspace:FindFirstChild("FlightSimAircraft",true)
	for _,name in ipairs(names) do
		local obj=workspace:FindFirstChild(name,true)
		if obj and obj:IsA("BasePart") then return obj end
		if tagged then
			obj=tagged:FindFirstChild(name,true)
			if obj and obj:IsA("BasePart") then return obj end
		end
	end
	return nil
end

local physicalDisplays={}

local function ensureSurfaceDisplay(part,name)
	if not part then return nil end
	local guiPart=part:FindFirstChild(name)
	if guiPart and guiPart:IsA("SurfaceGui") then return guiPart end
	local sg=Instance.new("SurfaceGui")
	sg.Name=name
	sg.Face=Enum.NormalId.Front
	sg.AlwaysOnTop=false
	sg.LightInfluence=0
	sg.MaxDistance=100
	sg.PixelsPerStud=100
	sg.Parent=part
	local label=Instance.new("TextLabel")
	label.Name="Display"
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.TextColor3=Color3.new(1,1,1)
	label.Font=Enum.Font.Code
	label.TextSize=18
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.TextYAlignment=Enum.TextYAlignment.Top
	label.Parent=sg
	return sg
end

local function refreshPhysicalDisplays()
	if physicalDisplays.ready then return end
	physicalDisplays.PFD=ensureSurfaceDisplay(findPhysicalDisplay({"PFDDisplay","CaptainPFD","LeftPFD"}),"FlightSimPFD")
	physicalDisplays.ND=ensureSurfaceDisplay(findPhysicalDisplay({"NDDisplay","CaptainND","LeftND"}),"FlightSimND")
	physicalDisplays.EICAS=ensureSurfaceDisplay(findPhysicalDisplay({"EICASDisplay","CenterEICAS","EngineDisplay"}),"FlightSimEICAS")
	physicalDisplays.ready=true
end

local function send(name,a,b)
 command:FireServer(name,a,b)
end

local function updateControls(dt)
 if UserInputService:GetFocusedTextBox() then return end
 controlAccumulator+=dt
 if controlAccumulator<0.05 then return end
 controlAccumulator=0

 local e,a,r,s=0,0,0,0
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then e+=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then e-=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.D) then a+=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.A) then a-=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.E) then r+=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.Q) then r-=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.C) then s+=1 end
 if UserInputService:IsKeyDown(Enum.KeyCode.Z) then s-=1 end

 local values={Elevator=e,Aileron=a,Rudder=r,NoseWheelSteering=s}
 for name,value in pairs(values) do
  if lastControl[name]~=value then
   lastControl[name]=value
   if name=="NoseWheelSteering" then
    send(name,value)
   else
    send("Control",name,value)
   end
  end
 end

 throttleAccumulator+=0.05
 if throttleAccumulator<0.1 then return end
 throttleAccumulator=0
 local up=UserInputService:IsKeyDown(Enum.KeyCode.PageUp) or UserInputService:IsKeyDown(Enum.KeyCode.RightBracket)
 local down=UserInputService:IsKeyDown(Enum.KeyCode.PageDown) or UserInputService:IsKeyDown(Enum.KeyCode.LeftBracket)
 local throttleRate=(up and 0.05) or (down and -0.05) or 0
 if throttleRate~=0 then
  throttle[1]=math.clamp(throttle[1]+throttleRate,0,1)
  throttle[2]=math.clamp(throttle[2]+throttleRate,0,1)
  send("Throttle",1,throttle[1])
  send("Throttle",2,throttle[2])
 end
end

UserInputService.InputBegan:Connect(function(input,processed)
 if processed or UserInputService:GetFocusedTextBox() then return end
 local k=input.KeyCode
 if k==Enum.KeyCode.P then
  battery=not battery; send("Battery",battery)
 elseif k==Enum.KeyCode.O then
  apu=not apu; send("APU",apu)
 elseif k==Enum.KeyCode.L then
  ap=not ap; send("AP",ap)
 elseif k==Enum.KeyCode.J then
  autoThrottle=not autoThrottle; send("AutoThrottle",autoThrottle)
 elseif k==Enum.KeyCode.X then
  send("GoAround",true)
 elseif k==Enum.KeyCode.M then
  mcpSpeed=math.clamp(mcpSpeed-5,60,350); send("MCPSpeed",mcpSpeed)
 elseif k==Enum.KeyCode.N then
  mcpSpeed=math.clamp(mcpSpeed+5,60,350); send("MCPSpeed",mcpSpeed)
 elseif k==Enum.KeyCode.K then
  mcpVS=math.clamp(mcpVS-250,-6000,6000); send("MCPVerticalSpeed",mcpVS)
 elseif k==Enum.KeyCode.I then
  mcpVS=math.clamp(mcpVS+250,-6000,6000); send("MCPVerticalSpeed",mcpVS)
 elseif k==Enum.KeyCode.F then
  flap=(flap==0) and 0.5 or ((flap==0.5) and 1 or 0); send("Flap",flap)
 elseif k==Enum.KeyCode.G then
  gearDown=not gearDown; send("Gear",gearDown)
 elseif k==Enum.KeyCode.B then
  parkingBrake=not parkingBrake; send("ParkingBrake",parkingBrake)
 elseif k==Enum.KeyCode.One then
  starter[1]=not starter[1]; send("EngineStarter",1,starter[1])
 elseif k==Enum.KeyCode.Two then
  starter[2]=not starter[2]; send("EngineStarter",2,starter[2])
 elseif k==Enum.KeyCode.R then
  fuel[1]=not fuel[1]; send("EngineFuel",1,fuel[1])
 elseif k==Enum.KeyCode.T then
  fuel[2]=not fuel[2]; send("EngineFuel",2,fuel[2])
 elseif k==Enum.KeyCode.Y then
  ignition[1]=not ignition[1]; send("EngineIgnition",1,ignition[1])
 elseif k==Enum.KeyCode.U then
  ignition[2]=not ignition[2]; send("EngineIgnition",2,ignition[2])
 end
end)

telemetry.OnClientEvent:Connect(function(state)
 refreshPhysicalDisplays()
 local e1,e2=state.Engines[1],state.Engines[2]
 local gs=state.GroundSteering or {}
 local at=state.AutoThrottle or {}
 local apState=state.Autopilot or {}
 local ei=state.EngineIntegration or {}
 local ac=state.ATC or {}
 local td=state.TCASDisplay or state.TCAS or {}
 local dec=state.ATCDecision or {}
 local messages=ac.LastMessage or ""
 if #messages>36 then messages=messages:sub(1,36).."…" end
 local trafficLevel=td.HighestLevel or "NONE"
 local trafficText=(trafficLevel=="RA" and "RA") or (trafficLevel=="TA" and "TA") or "NONE"
 local decisionText=dec.Instruction or "NONE"
 local intruder=td.ClosestIntruder or dec.ConflictWith or "-"
 local range=td.ClosestRangeM or dec.DistanceM or 0

 pfd.Text=string.format("PFD\nALT %5.0fft  IAS %4.0fkt\nHDG %03.0f°  PITCH %+4.1f°\nROLL %+4.1f°  VS %+5.0f\nAP %-3s  AT %-3s",state.Altitude,state.Airspeed,state.Heading,state.Pitch,state.Roll,state.VerticalSpeed,apState.Enabled and "ON" or "OFF",at.Enabled and "ON" or "OFF")
 nd.Text=string.format("ND\nMODE %-6s  WPT %d\nDTW %5.1f  BRG %03.0f\nXTK %+5.2f  IRS %-3s\nRADAR %-3s  TCAS %-3s",state.Navigation.Mode or "HDG",state.Navigation.ActiveWaypoint or 0,state.Navigation.DistanceToWaypoint or 0,state.Navigation.BearingToWaypoint or 0,state.Navigation.CrossTrackError or 0,state.IRS.Mode or "OFF",state.Avionics.WeatherRadar and "ON" or "OFF",trafficText)
 eicas.Text=string.format("EICAS\nENG1 N1 %5.1f N2 %5.1f EGT %4.0f\nENG2 N1 %5.1f N2 %5.1f EGT %4.0f\nHYD A %4.0f  B %4.0f  STBY %4.0f\nELEC B1 %s B2 %s APU %s\nGEAR %s  FLAP %3.0f%%\nWARN %s  CAUT %s",e1.N1,e1.N2,e1.EGT,e2.N1,e2.N2,e2.EGT,state.Hydraulic.A.Pressure,state.Hydraulic.B.Pressure,state.Hydraulic.Standby.Pressure,tostring(state.Electrical.Bus1),tostring(state.Electrical.Bus2),tostring(state.Electrical.APUGeneratorAvailable),state.GearStatus.Warning and "WARN" or "OK",(state.Controls.Flap or 0)*100,tostring((state.Annunciation or {}).MasterWarning or false),tostring((state.Annunciation or {}).MasterCaution or false))
 if physicalDisplays.PFD then
	local label=physicalDisplays.PFD:FindFirstChild("Display")
	if label then label.Text=pfd.Text end
 end
 if physicalDisplays.ND then
	local label=physicalDisplays.ND:FindFirstChild("Display")
	if label then label.Text=nd.Text end
 end
 if physicalDisplays.EICAS then
	local label=physicalDisplays.EICAS:FindFirstChild("Display")
	if label then label.Text=eicas.Text end
 end

 readout.Text=string.format(
  "PHASE %-14s  ATC %-9s\nALT %6.0f ft  IAS %5.0f kt  HDG %6.1f°\nP/R %5.1f/%5.1f°  VS %6.0f fpm\n\nENG1 N1 %5.1f N2 %5.1f EGT %4.0f RUN %s\nENG2 N1 %5.1f N2 %5.1f EGT %4.0f RUN %s\nASYM %+5.2f  YAWM %+7.3f  OUT %s\n\nELEC BAT %s APU %s BUS %s/%s\nHYD A %4.0f psi B %4.0f psi\nFUEL %7.0f  GEAR %s  FLAP %3.0f%%  BRK %s\nSTEER %s %5.1f°  YAW %5.1f°/s\nAP %s %-10s ALT %6.0f\nA/T %s %-14s SPD %6.0f ERR %+5.1f\nPROT %-10s CMD %.2f/%.2f\n\nATC %s  SQWK %s  READBACK %s\nTRAFFIC %-4s  INTRUDER %-12s  RANGE %5.0fm\nATC DECISION %-14s",
  state.Phase,ac.Phase or "COLD",state.Altitude,state.Airspeed,state.Heading,state.Pitch,state.Roll,state.VerticalSpeed,
  e1.N1,e1.N2,e1.EGT,tostring(e1.Running),e2.N1,e2.N2,e2.EGT,tostring(e2.Running),
  ei.ThrustAsymmetry or 0,ei.YawMoment or 0,tostring(ei.EngineOut),
  tostring(state.Electrical.Battery),tostring(state.Electrical.APU),tostring(state.Electrical.Bus1),tostring(state.Electrical.Bus2),
  state.Hydraulic.A.Pressure or 0,state.Hydraulic.B.Pressure or 0,state.Fuel.Total,
  state.Gear.Nose and "DOWN" or "UP",state.Controls.Flap*100,state.Brakes.Parking and "SET" or "OFF",
  gs.Available and "AVAIL" or "OFF",gs.NoseWheelAngle or 0,gs.YawRate or 0,
  tostring(apState.Enabled),apState.Mode or "OFF",apState.TargetAltitude or 0,
  tostring(at.Enabled),at.Mode or "OFF",at.TargetSpeed or 0,at.SpeedError or 0,
  at.Protection or "NONE",at.ThrottleCommand and at.ThrottleCommand[1] or 0,at.ThrottleCommand and at.ThrottleCommand[2] or 0,
  messages,ac.Squawk or "2000",tostring(ac.ReadbackValid),trafficText,tostring(intruder),range,decisionText
 )
end)

RunService.RenderStepped:Connect(updateControls)
