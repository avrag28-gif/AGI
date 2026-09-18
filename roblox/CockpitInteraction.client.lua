-- FlightSim cockpit interaction layer v1.1
-- Physical controls expose Attributes: Command, A, B, Toggle.
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

local function activate(obj)
 local c=obj:GetAttribute("Command")
 if type(c)~="string" or c=="" then return end
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
