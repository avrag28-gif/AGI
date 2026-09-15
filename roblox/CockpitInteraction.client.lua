-- FlightSim cockpit interaction layer.
-- Attach ClickDetectors/ProximityPrompts to cockpit controls with Attribute Command.
-- Attributes: Command, A, B, Toggle. The command is sent to the server.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local rem=RS:WaitForChild("FlightSim"):WaitForChild("Remotes")
local command=rem:WaitForChild("AircraftCommand")

local function send(control,a,b) command:FireServer(control,a,b) end
local function activate(obj)
 local c=obj:GetAttribute("Command")
 if type(c)~="string" or c=="" then return end
 local a=obj:GetAttribute("A")
 local b=obj:GetAttribute("B")
 if obj:GetAttribute("Toggle") then
  local current=obj:GetAttribute("State") == true
  current=not current
  obj:SetAttribute("State",current)
  b=current
 end
 send(c,a,b)
end

local function bind(root)
 for _,obj in ipairs(root:GetDescendants()) do
  if obj:IsA("ClickDetector") then obj.MouseClick:Connect(function(p) if p==player then activate(obj.Parent) end end)
  elseif obj:IsA("ProximityPrompt") then obj.Triggered:Connect(function(p) if p==player then activate(obj.Parent) end end)
  end
 end
end

bind(workspace)
workspace.DescendantAdded:Connect(function(obj)
 if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
  task.defer(function() bind(obj.Parent) end)
 end
end)

-- Optional generic cockpit mouse interaction: highlighted controls can expose
-- a String Attribute named Command and numeric/string A/B attributes.
local highlight=Instance.new("Highlight")
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
