-- FlightSim modular runtime v0.8
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local root=script.Parent; local systemsFolder=root:WaitForChild("FlightSimSystems")
local shared=ReplicatedStorage:WaitForChild("FlightSim"); local remotes=shared:WaitForChild("Remotes")
local Config=require(systemsFolder:WaitForChild("Config")); local State=require(systemsFolder:WaitForChild("State"))
local Electrical=require(systemsFolder:WaitForChild("Electrical")); local Engine=require(systemsFolder:WaitForChild("Engine")); local Core=require(systemsFolder:WaitForChild("Core"))
local FlightControls=require(systemsFolder:WaitForChild("FlightControls")); local LandingGear=require(systemsFolder:WaitForChild("LandingGear")); local Brakes=require(systemsFolder:WaitForChild("Brakes")); local Avionics=require(systemsFolder:WaitForChild("Avionics"))
local Navigation=require(systemsFolder:WaitForChild("Navigation")); local WaypointManager=require(systemsFolder:WaitForChild("WaypointManager")); local Autopilot=require(systemsFolder:WaitForChild("Autopilot")); local VNAV=require(systemsFolder:WaitForChild("VNAV")); local FMC=require(systemsFolder:WaitForChild("FMC")); local MCP=require(systemsFolder:WaitForChild("MCP")); local Physics=require(systemsFolder:WaitForChild("Physics"))
local Radio=require(systemsFolder:WaitForChild("Radio")); local Transponder=require(systemsFolder:WaitForChild("Transponder")); local AircraftRegistry=require(systemsFolder:WaitForChild("AircraftRegistry")); local CommandRouter=require(systemsFolder:WaitForChild("CommandRouter"))
local registry=AircraftRegistry.new(); local simulations={}
local function get(id,key) local s=simulations[id]; return s and s[key] end
local router=CommandRouter.new(registry,function(id)return get(id,"fmc") end,function(id)return get(id,"radio") end,function(id)return get(id,"transponder") end,function(id)return get(id,"mcp") end)
local function createAircraftForPlayer(player)
 local id="P_"..tostring(player.UserId); if registry:Get(id) then return end
 local state=State.new(); registry:Register(id,state,player)
 simulations[id]={state=state,electrical=Electrical.new(state),engine=Engine.new(state),core=Core.new(state),flightControls=FlightControls.new(state),landingGear=LandingGear.new(state),brakes=Brakes.new(state),avionics=Avionics.new(state),navigation=Navigation.new(state),waypoints=WaypointManager.new(state),autopilot=Autopilot.new(state),vnav=VNAV.new(state),fmc=FMC.new(state),mcp=MCP.new(state),radio=Radio.new(state),transponder=Transponder.new(state),physics=Physics.new(state)}
end
local function removeAircraftForPlayer(player) local id="P_"..tostring(player.UserId); registry:Unregister(id); simulations[id]=nil end
Players.PlayerAdded:Connect(createAircraftForPlayer); Players.PlayerRemoving:Connect(removeAircraftForPlayer); for _,p in Players:GetPlayers() do createAircraftForPlayer(p) end
local commandRemote=remotes:FindFirstChild("AircraftCommand")
if commandRemote then commandRemote.OnServerEvent:Connect(function(player,command,a,b) local id=registry:GetForPlayer(player); if not id then return end; local ok,reason=router:Handle(player,id,command,a,b); if not ok then warn("[FlightSim] rejected command",player.Name,reason) end end) end
local accumulator,telemetryAccumulator=0,0; local fixedStep=1/(tonumber(Config.SimulationRate) or 60)
local function simulationStep(dt)
 registry:ForEach(function(id)
  local s=simulations[id]; if not s then return end
  s.electrical:Step(dt); s.engine:Step(dt); s.electrical:Step(dt); s.core:Step(dt)
  s.fmc:Step(dt); s.waypoints:Step(dt); s.navigation:Step(dt); s.vnav:Step(dt); s.mcp:Step(dt); s.autopilot:Step(dt)
  s.flightControls:Step(dt); s.landingGear:Step(dt); s.brakes:Step(dt); s.avionics:Step(dt); s.radio:Step(dt); s.transponder:Step(dt); s.physics:Step(dt)
 end)
end
RunService.Heartbeat:Connect(function(frameDt)
 frameDt=math.min(frameDt,0.25); accumulator+=frameDt
 while accumulator>=fixedStep do simulationStep(fixedStep); accumulator-=fixedStep end
 telemetryAccumulator+=frameDt
 if telemetryAccumulator>=1/(tonumber(Config.TelemetryRate) or 20) then telemetryAccumulator=0; local t=remotes:FindFirstChild("Telemetry"); if t then registry:ForEach(function(_,state,owner) if owner then t:FireClient(owner,state:Get()) end end) end end
end)
print("[FlightSim] Modular runtime online",Config.Aircraft or "Unknown aircraft")
