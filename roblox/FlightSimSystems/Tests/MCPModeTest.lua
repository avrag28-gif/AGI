-- Regression tests for MCP mode coupling and command surface.
local MCP=require(script.Parent.Parent.MCP)
local function assertTrue(v,msg) assert(v,msg) end
local function assertEqual(a,b,msg) assert(a==b,msg.." got="..tostring(a).." expected="..tostring(b)) end
local function makeState(data) local state={data=data}; function state:Get() return self.data end; return state end

local data={Autopilot={},Navigation={},VNAV={}}
local mcp=MCP.new(makeState(data))
assertTrue(mcp:SetHeading(370),"heading setter failed")
assertEqual(data.Autopilot.TargetHeading,10,"heading must wrap")
assertTrue(mcp:SetAltitude(12000),"altitude setter failed")
assertEqual(data.Autopilot.TargetAltitude,12000,"altitude mismatch")
assertTrue(mcp:SetSpeed(250),"speed setter failed")
assertEqual(data.Autopilot.TargetSpeed,250,"speed mismatch")
assertTrue(mcp:SetVerticalSpeed(-1800),"VS setter failed")
assertEqual(data.Autopilot.TargetVerticalSpeed,-1800,"VS mismatch")
assertTrue(mcp:SetMode("VNAV"),"VNAV mode failed")
assertTrue(data.Autopilot.Enabled,"VNAV should enable AP")
assertEqual(data.Navigation.Mode,nil,"VNAV must not overwrite lateral nav mode")
assertEqual(data.VNAV.Mode,"VNAV","VNAV state mismatch")
mcp:SetMode("VS")
assertEqual(data.VNAV.Mode,"OFF","VS must exit VNAV")
mcp:Step(1/60)
assertEqual(data.Navigation.CommandVerticalSpeed,-1800,"VS command not propagated")
mcp:SetMode("OFF")
assertTrue(not data.Autopilot.Enabled,"OFF must disable AP")
assertEqual(data.VNAV.Mode,"OFF","OFF must clear VNAV")
print("MCPModeTest PASS")
return true
