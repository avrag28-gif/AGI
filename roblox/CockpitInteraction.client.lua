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
-- MCP 3D contract:
-- Add ClickDetector to each physical MCP knob/button part and set:
-- Interaction="MCP_KNOB", Command="MCPHeading|MCPAltitude|MCPSpeed|MCPVerticalSpeed",
-- Step/Min/Max/Wrap/Direction/ValueAttribute as needed. Left click increments;
-- right click decrements. AP/A/T mode buttons can use Command="AP" or "AutoThrottle"
-- with A=true and Toggle=true. MCP mode selectors use Command="MCPMode", A="HDG|LNAV|VNAV|APP|VOR|ALT_HOLD|LCHG|VS|OFF".


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

local function activateKnob(obj,c,directionOverride)
 local aircraft=findAircraftForControl(obj)
 local attr=obj:GetAttribute("ValueAttribute")
 if type(attr)~="string" or attr=="" then attr=knobValueAttribute(c) end
 local current=attr and aircraft and finite(aircraft:GetAttribute(attr),nil)
 local step=finite(obj:GetAttribute("Step"),1)
 local direction=finite(directionOverride,finite(obj:GetAttribute("Direction"),1))
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
 if obj:GetAttribute("Interaction")=="MCP_KNOB" and obj:FindFirstChildWhichIsA("DragDetector") then
  return
 end
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

local rotaryBound={}

local function setupRotaryKnob(obj)
 if rotaryBound[obj] then return end
 if obj:GetAttribute("Interaction")~="MCP_KNOB" then return end
 local detector=obj:FindFirstChildWhichIsA("DragDetector")
 if not detector then return end
 local commandName=obj:GetAttribute("Command")
 if type(commandName)~="string" or commandName=="" then return end
 local aircraft=findAircraftForControl(obj)
 if not aircraft then return end
 detector.DragStyle=Enum.DragDetectorDragStyle.RotateAxis
 detector.ResponseStyle=Enum.DragDetectorResponseStyle.Custom
 detector.Axis=Vector3.yAxis
 detector.Enabled=true
 local axisName=obj:GetAttribute("RotateAxis")
 if axisName=="X" then detector.Axis=Vector3.xAxis elseif axisName=="Z" then detector.Axis=Vector3.zAxis end
 local minValue=obj:GetAttribute("Min")
 local maxValue=obj:GetAttribute("Max")
 local step=finite(obj:GetAttribute("Step"),1)
 local direction=finite(obj:GetAttribute("Direction"),1)
 local degreesPerStep=finite(obj:GetAttribute("DegreesPerStep"),3.6)
 if degreesPerStep<=0 then degreesPerStep=3.6 end
 local startFrame,startValue,lastSent
 rotaryBound[obj]=true
 detector.DragStart:Connect(function(p)
  if p~=player then return end
  startFrame=detector.DragFrame
  local attr=obj:GetAttribute("ValueAttribute")
  if type(attr)~="string" or attr=="" then attr=knobValueAttribute(commandName) end
  startValue=attr and finite(aircraft:GetAttribute(attr),nil)
  if startValue==nil then startValue=finite(obj:GetAttribute("Value"),0) end
  lastSent=startValue
 end)
 detector.DragContinue:Connect(function(p)
  if p~=player or not startFrame or startValue==nil then return end
  local relative=startFrame:ToObjectSpace(detector.DragFrame)
  local rx,ry,rz=relative:ToOrientation()
  local angle=ry
  if axisName=="X" then angle=rx elseif axisName=="Z" then angle=rz end
  local detents=math.floor((angle*180/math.pi)/degreesPerStep+0.5)
  local nextValue=startValue+detents*step*direction
  if type(minValue)=="number" and type(maxValue)=="number" then
   if obj:GetAttribute("Wrap")==true then
    local span=maxValue-minValue
    if span>0 then while nextValue>maxValue do nextValue-=span end while nextValue<minValue do nextValue+=span end end
   else nextValue=math.clamp(nextValue,minValue,maxValue) end
  end
  nextValue=math.round(nextValue/step)*step
  if nextValue~=lastSent then
   lastSent=nextValue
   obj:SetAttribute("Value",nextValue)
   send(commandName,nextValue,nil)
  end
 end)
 detector.DragEnd:Connect(function(p)
  if p==player then startFrame=nil startValue=nil lastSent=nil end
 end)
end
local function bindDetector(detector)
 if bound[detector] then return end
 local parent=detector.Parent
 if not parent then return end
 bound[detector]=true
 if detector:IsA("ClickDetector") then
  detector.MouseClick:Connect(function(p)
   if p==player then
    if parent:GetAttribute("Interaction")=="MCP_KNOB" then activateKnob(parent,parent:GetAttribute("Command"),1) else activate(parent) end
   end
  end)
  detector.RightMouseClick:Connect(function(p)
   if p==player and parent:GetAttribute("Interaction")=="MCP_KNOB" then
    activateKnob(parent,parent:GetAttribute("Command"),-1)
   end
  end)
 elseif detector:IsA("ProximityPrompt") then
  detector.Triggered:Connect(function(p)
   if p==player then activate(parent) end
  end)
 end
end

for _,obj in ipairs(workspace:GetDescendants()) do
 if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then bindDetector(obj) end
 if obj:IsA("BasePart") or obj:IsA("Model") then setupRotaryKnob(obj) end
end

workspace.DescendantAdded:Connect(function(obj)
 if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
  task.defer(bindDetector,obj)
 elseif obj:IsA("DragDetector") then
  task.defer(function() setupRotaryKnob(obj.Parent) end)
 elseif obj:IsA("BasePart") or obj:IsA("Model") then
  task.defer(function() setupRotaryKnob(obj) end)
 end
end)

local function syncMCPKnobValues()
 for obj in pairs(rotaryBound) do
  if obj and obj.Parent and obj:GetAttribute("Interaction")=="MCP_KNOB" then
   local aircraft=findAircraftForControl(obj)
   local commandName=obj:GetAttribute("Command")
   local attr=obj:GetAttribute("ValueAttribute")
   if type(attr)~="string" or attr=="" then attr=knobValueAttribute(commandName) end
   if aircraft and attr then
    local value=aircraft:GetAttribute(attr)
    if type(value)=="number" then obj:SetAttribute("Value",value) end
   end
  end
 end
end


local highlight=Instance.new("Highlight")
highlight.Name="FlightSimControlHighlight"
highlight.Enabled=false
highlight.DepthMode=Enum.HighlightDepthMode.Occluded
highlight.Parent=workspace

local mouse=player:GetMouse()
RunService.RenderStepped:Connect(function()
 syncMCPKnobValues()
 local target=mouse.Target
 if target and target:GetAttribute("Command") then
  highlight.Adornee=target
  highlight.Enabled=true
 else
  highlight.Adornee=nil
  highlight.Enabled=false
 end
end)
