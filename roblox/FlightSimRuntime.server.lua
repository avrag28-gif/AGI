-- FlightSim modular runtime v2.6
local Players=game:GetService("Players"); local RunService=game:GetService("RunService"); local ReplicatedStorage=game:GetService("ReplicatedStorage")
local root=script.Parent; local systemsFolder=root:WaitForChild("FlightSimSystems"); local shared=ReplicatedStorage:WaitForChild("FlightSim"); local remotes=shared:WaitForChild("Remotes")
local Config=require(systemsFolder:WaitForChild("Config")); local State=require(systemsFolder:WaitForChild("State")); local Electrical=require(systemsFolder:WaitForChild("Electrical")); local APU=require(systemsFolder:WaitForChild("APU")); local Engine=require(systemsFolder:WaitForChild("Engine")); local Core=require(systemsFolder:WaitForChild("Core")); local Hydraulic=require(systemsFolder:WaitForChild("Hydraulic")); local Fuel=require(systemsFolder:WaitForChild("Fuel")); local FireProtection=require(systemsFolder:WaitForChild("FireProtection")); local Annunciation=require(systemsFolder:WaitForChild("Annunciation")); local FlightControls=require(systemsFolder:WaitForChild("FlightControls")); local LandingGear=require(systemsFolder:WaitForChild("LandingGear")); local Brakes=require(systemsFolder:WaitForChild("Brakes")); local Avionics=require(systemsFolder:WaitForChild("Avionics")); local Navigation=require(systemsFolder:WaitForChild("Navigation")); local Autopilot=require(systemsFolder:WaitForChild("Autopilot")); local VNAV=require(systemsFolder:WaitForChild("VNAV")); local FMC=require(systemsFolder:WaitForChild("FMC")); local MCP=require(systemsFolder:WaitForChild("MCP")); local Approach=require(systemsFolder:WaitForChild("Approach")); local VOR=require(systemsFolder:WaitForChild("VOR")); local LandingModel=require(systemsFolder:WaitForChild("LandingModel")); local LandingDynamics=require(systemsFolder:WaitForChild("LandingDynamics")); local Physics=require(systemsFolder:WaitForChild("Physics")); local Trim=require(systemsFolder:WaitForChild("Trim")); local Flaps=require(systemsFolder:WaitForChild("Flaps")); local Radio=require(systemsFolder:WaitForChild("Radio")); local Transponder=require(systemsFolder:WaitForChild("Transponder")); local GroundSteering=require(systemsFolder:WaitForChild("GroundSteering")); local Failures=require(systemsFolder:WaitForChild("Failures")); local AircraftRegistry=require(systemsFolder:WaitForChild("AircraftRegistry")); local CommandRouter=require(systemsFolder:WaitForChild("CommandRouter"))
local registry=AircraftRegistry.new(); local simulations={}; local function get(id,key) local s=simulations[id]; return s and s[key] end
local router=CommandRouter.new(registry,function(id)return get(id,"fmc") end,function(id)return get(id,"radio") end,function(id)return get(id,"transponder") end,function(id)return get(id,"mcp") end,function(id)return get(id,"approach") end)
local function createAircraftForPlayer(player)
 local id="P_"..tostring(player.UserId); if registry:Get(id) then return end; local state=State.new(); registry:Register(id,state,player)
 simulations[id]={state=state,apu=APU.new(state),electrical=Electrical.new(state),engine=Engine.new(state),failures=Failures.new(state),core=Core.new(state),hydraulic=Hydraulic.new(state,Config),fuel=Fuel.new(state),fireProtection=FireProtection.new(state),annunciation=Annunciation.new(state),flightControls=FlightControls.new(state),landingGear=LandingGear.new(state),brakes=Brakes.new(state),avionics=Avionics.new(state),navigation=Navigation.new(state),autopilot=Autopilot.new(state),vnav=VNAV.new(state),fmc=FMC.new(state),mcp=MCP.new(state),approach=Approach.new(state),vor=VOR.new(state),landing=LandingModel.new(state),landingDynamics=LandingDynamics.new(state),flaps=Flaps.new(state),radio=Radio.new(state),transponder=Transponder.new(state),trim=Trim.new(state),groundSteering=GroundSteering.new(state),physics=Physics.new(state)}
end
local function removeAircraftForPlayer(player) local id="P_"..tostring(player.UserId); registry:Unregister(id); simulations[id]=nil end
Players.PlayerAdded:Connect(createAircraftForPlayer); Players.PlayerRemoving:Connect(removeAircraftForPlayer); for _,p in Players:GetPlayers() do createAircraftForPlayer(p) end
local commandRemote=remotes:FindFirstChild("AircraftCommand"); if commandRemote then commandRemote.OnServerEvent:Connect(function(player,command,a,b) local id=registry:GetForPlayer(player); if not id then return end; local ok,reason=router:Handle(player,id,command,a,b); if not ok then warn("[FlightSim] rejected command",player.Name,reason) end end) end
local accumulator,telemetryAccumulator=0,0; local fixedStep=1/(tonumber(Config.SimulationRate) or 60)
local function simulationStep(dt)
 registry:ForEach(function(id)
  local s=simulations[id]; if not s then return end
  s.apu:Step(dt); s.fuel:Step(dt); s.engine:Step(dt); s.fireProtection:Step(dt); s.failures:Step(dt); s.electrical:Step(dt); s.core:Step(dt)
  -- Electrical-powered avionics and radios are resolved before navigation receivers.
  s.avionics:Step(dt); s.radio:Step(dt)
  -- Pilot selections precede computed navigation/guidance.
  s.fmc:Step(dt); s.mcp:Step(dt); s.navigation:Step(dt); s.approach:Step(dt); s.vor:Step(dt); s.vnav:Step(dt); s.autopilot:Step(dt); s.trim:Step(dt); s.flaps:Step(dt)
  -- NAV1 is a single receiver path: valid ILS claims first; otherwise VOR may claim it.
  s.flightControls:Step(dt); s.landingGear:Step(dt); s.brakes:Step(dt)
  s.hydraulic:Step(dt)
  s.groundSteering:Step(dt); s.transponder:Step(dt); s.physics:Step(dt); s.landing:Step(dt); s.landingDynamics:Step(dt); s.annunciation:Step(dt)
 end)
end
RunService.Heartbeat:Connect(function(frameDt)
 frameDt=math.min(frameDt,0.25); accumulator+=frameDt
 while accumulator>=fixedStep do simulationStep(fixedStep); accumulator-=fixedStep end
 telemetryAccumulator+=frameDt
 if telemetryAccumulator>=1/(tonumber(Config.TelemetryRate) or 20) then telemetryAccumulator=0; local t=remotes:FindFirstChild("Telemetry"); if t then registry:ForEach(function(_,state,owner) if owner then t:FireClient(owner,state:Get()) end end) end end
end)
print("[FlightSim] Modular runtime online",Config.Aircraft or "Unknown aircraft")
