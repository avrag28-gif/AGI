-- FlightSim TCAS/ND traffic presentation v0.2
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("FlightSim"):WaitForChild("Remotes")
local telemetry=remotes:WaitForChild("Telemetry")
local gui=Instance.new("ScreenGui"); gui.Name="FlightSimTrafficDisplay"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame"); root.Name="TrafficND"; root.Size=UDim2.fromOffset(260,260); root.Position=UDim2.new(1,-280,0,18); root.BackgroundTransparency=.08; root.Parent=gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=root
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,24); title.BackgroundTransparency=1; title.Text="TRAFFIC"; title.Font=Enum.Font.GothamBold; title.TextSize=14; title.Parent=root
local rangeLabel=Instance.new("TextLabel"); rangeLabel.Position=UDim2.fromOffset(8,24); rangeLabel.Size=UDim2.new(1,-16,0,18); rangeLabel.BackgroundTransparency=1; rangeLabel.Text="RANGE 5 NM"; rangeLabel.Font=Enum.Font.Code; rangeLabel.TextSize=11; rangeLabel.Parent=root
local field=Instance.new("Frame"); field.Position=UDim2.fromOffset(30,48); field.Size=UDim2.fromOffset(200,200); field.BackgroundTransparency=1; field.Parent=root
local function line(pos,size) local f=Instance.new("Frame"); f.AnchorPoint=Vector2.new(.5,.5); f.Position=pos; f.Size=size; f.BackgroundTransparency=.55; f.Parent=field end
line(UDim2.fromScale(.5,.5),UDim2.new(1,0,0,1)); line(UDim2.fromScale(.5,.5),UDim2.new(0,1,1,0))
local own=Instance.new("TextLabel"); own.AnchorPoint=Vector2.new(.5,.5); own.Position=UDim2.fromScale(.5,.5); own.Size=UDim2.fromOffset(28,22); own.BackgroundTransparency=1; own.Text="▲"; own.TextSize=18; own.Font=Enum.Font.GothamBold; own.Parent=field
local targets={}
local function clearTargets() for _,v in pairs(targets) do v:Destroy() end; targets={} end
local function addTarget(t)
 local rb=tonumber(t.RelativeBearing); local range=tonumber(t.RangeM); if not rb or not range then return end
 local radius=math.clamp(range/(1852*5),0,1)*92; local rad=math.rad(rb); local px=.5+math.sin(rad)*radius/200; local py=.5-math.cos(rad)*radius/200
 local dot=Instance.new("TextLabel"); dot.AnchorPoint=Vector2.new(.5,.5); dot.Position=UDim2.fromScale(px,py); dot.Size=UDim2.fromOffset(72,34); dot.BackgroundTransparency=1; dot.Font=Enum.Font.Code; dot.TextSize=11
 local delta=tonumber(t.RelativeAltitudeFt) or 0; local sign=delta>=0 and "+" or "-"; dot.Text=string.format("%s\n%s%d",t.Level or "TA",sign,math.floor(math.abs(delta)/100)); dot.Parent=field; targets[#targets+1]=dot
end
telemetry.OnClientEvent:Connect(function(state)
 local td=state.TCASDisplay or {}; clearTargets(); root.Visible=td.Powered==true; if not root.Visible then return end
 rangeLabel.Text=string.format("RANGE 5 NM   %s",td.Level or "NONE")
 for _,t in ipairs(td.Targets or {}) do addTarget(t) end
end)
