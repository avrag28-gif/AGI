-- MCP integration regression tests.
-- Execute inside Roblox Studio/TestService where Vector3 and Luau runtime are available.
local State=require(script.Parent.State)
local MCP=require(script.Parent.MCP)

local function check(condition,message)
	if not condition then error("MCPIntegrationTest: "..message,2) end
end

local state=State.new()
local mcp=MCP.new(state)

check(mcp:SetHeading(725)==true,"heading command should be accepted")
check(state:Get().Autopilot.TargetHeading==5,"heading should wrap to 0..359")
check(state:Get().MCP.Heading==5,"MCP heading display state should mirror target")

check(mcp:SetAltitude(41000)==true,"altitude command should be accepted")
check(state:Get().Autopilot.TargetAltitude==41000,"autopilot altitude target should update")
check(state:Get().MCP.Altitude==41000,"MCP altitude display state should mirror target")

check(mcp:SetSpeed(280)==true,"speed command should be accepted")
check(state:Get().Autopilot.TargetSpeed==280,"autothrottle/autopilot speed target should update")
check(state:Get().MCP.Speed==280,"MCP speed display state should mirror target")

check(mcp:SetVerticalSpeed(-1500)==true,"vertical speed command should be accepted")
check(state:Get().Autopilot.TargetVerticalSpeed==-1500,"vertical speed target should update")
check(state:Get().MCP.VerticalSpeed==-1500,"MCP VS display state should mirror target")

check(mcp:SetMode("HDG")==true,"HDG mode should be accepted")
check(state:Get().Autopilot.Enabled==true,"MCP mode should engage autopilot")
check(state:Get().Autopilot.Mode=="HDG","AP mode should follow MCP mode")
check(state:Get().MCP.HeadingMode=="HDG SEL","MCP heading annunciation should update")

check(mcp:SetMode("VS")==true,"VS mode should be accepted")
check(state:Get().MCP.VerticalSpeedMode=="VS","MCP VS annunciation should update")

check(mcp:SetMode("OFF")==true,"OFF mode should be accepted")
check(state:Get().Autopilot.Enabled==false,"OFF should disengage autopilot")

return true
