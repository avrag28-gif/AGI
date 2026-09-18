-- FlightSim cockpit interaction layer v1.1
-- Physical controls expose Attributes: Command, A, B, Toggle.
-- MCP knobs can additionally use Interaction="MCP_KNOB", Step, Min, Max,
-- Wrap, Direction and ValueAttribute. A click advances the knob deterministically.
-- The script binds each ClickDetector/ProximityPrompt exactly once.

local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local rem=RS:WaitForChild("FlightSim"):WaitForChild("Remotes")
local command=rem:WaitForChild("AircraftCommand")
local bound={}

local function send(control,a,b)
 command:FireServer(control,a,b)
end

local function finite(v,d)
 v=tonumber(v)
 if v and v==v and v~=math.huge and v~=-math.huge then return v end
 return d
end

local function findAircraftForControl(obj)
 local model=obj:FindFirstAncestorOfClass("Model")
 while model do
  if model:GetAttribute("FlightSimAircraftId") then return model end
  model=model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
 end
 return nil
end

local function knobValueAttribute(commandName)
 if commandName=="MCPHeading" then return "FlightSimMCPHeading" end
 if commandName=="MCPAltitude" then return "FlightSimMCPAltitude" end
 if commandName=="MCPSpeed" or commandName=="MCPspeed" then return "FlightSimMCPSpeed" end
 if commandName=="MCPVerticalSpeed" then return "FlightSimMCPVerticalSpeed" end
 return nil
end

local function activateKnob(obj,c)
 local aircraft=findAircraftForControl(obj)
 local attr=obj:GetAttribute("ValueAttribute")
 if type(attr)~="string" or attr=="" then attr=knobValueAttribute(c) end
 local current=attr and aircraft and finite(aircraft:GetAttribute(attr),nil)
 local step=finite(obj:GetAttribute("Step"),1)
 local direction=finite(obj:GetAttribute("Direction"),1)
 if current==nil then current=finite(obj:GetAttribute("Value"),0) end
 local minValue=obj:GetAttribute("Min")
 local maxValue=obj:GetAttribute("Max")
 local nextValue=current+step*direction
 if type(minValue)=="number" and type(maxValue)=="number" then
  if obj:GetAttribute("Wrap")==true then
   local span=maxValue-minValue
   if span>0 then
    while nextValue>maxValue do nextValue-=span end
    while nextValue<minValue do nextValue+=span end
   end
  else
   nextValue=math.clamp(nextValue,minValue,maxValue)
  end
 end
 obj:SetAttribute("Value",nextValue)
 send(c,nextValue,nil)
end

local function activate(obj)
 local c=obj:GetAttribute("Command")
 if type(c)~="string" or c=="" then return end
 if obj:GetAttribute("Interaction")=="MCP_KNOB" then
  activateKnob(obj,c)
  return
 end
 local a=obj:GetAttribute("A")
 local b=obj:GetAttribute("B")
 if obj:GetAttribute("Toggle")==true then
  local current=obj:GetAttribute("State")==true
  current=not current
  obj:SetAttribute("State",current)
  b=current
 end
 send(c,a,b)
end

local function bindDetector(detector)
 if bound[detector] then return end
 local parent=detector.Parent
 if not parent then return end
 bound[detector]=true
 if detector:IsA("ClickDetector") then
  detector.MouseClick:Connect(function(p)
   if p==player then activate(parent) end
  end)
 elseif detector:IsA("ProximityPrompt") then
  detector.Triggered:Connect(function(p)
   if p==player then activate(parent) end
  end)
 end
end

for _,obj in ipairs(workspace:GetDescendants()) do
 if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
  bindDetector(obj)
 end
end

workspace.DescendantAdded:Connect(function(obj)
 if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
  task.defer(bindDetector,obj)
 end
end)

local highlight=Instance.new("Highlight")
highlight.Name="FlightSimControlHighlight"
highlight.Enabled=false
highlight.DepthMode=Enum.HighlightDepthMode.Occluded
highlight.Parent=workspace

local mouse=player:GetMouse()
RunService.RenderStepped:Connect(function()
 local target=mouse.Target
 if target and target:GetAttribute("Command") then
  highlight.Adornee=target
  highlight.Enabled=true
 else
  highlight.Adornee=nil
  highlight.Enabled=false
 end
end)
