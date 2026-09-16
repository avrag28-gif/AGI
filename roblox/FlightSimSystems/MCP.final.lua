-- FlightSim 737-style MCP mode panel foundation v0.2
-- MCP stores pilot-selected targets/modes. Navigation owns computed guidance outputs.
local MCP={}; MCP.__index=MCP
local VALID={HDG=true,LNAV=true,VNAV=true,VOR=true,APP=true,ALT_HOLD=true,LCHG=true,VS=true,OFF=true}
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function MCP.new(state) return setmetatable({state=state},MCP) end
function MCP:SetHeading(v)
 v=tonumber(v); if not finite(v) then return false,"invalid_heading" end
 self.state:Get().Autopilot.TargetHeading=v%360; return true
end
function MCP:SetAltitude(v)
 v=tonumber(v); if not finite(v) then return false,"invalid_altitude" end
 self.state:Get().Autopilot.TargetAltitude=math.clamp(v,0,60000); return true
end
function MCP:SetSpeed(v)
 v=tonumber(v); if not finite(v) then return false,"invalid_speed" end
 self.state:Get().Autopilot.TargetSpeed=math.clamp(v,60,350); return true
end
function MCP:SetVerticalSpeed(v)
 v=tonumber(v); if not finite(v) then return false,"invalid_vertical_speed" end
 self.state:Get().Autopilot.TargetVerticalSpeed=math.clamp(v,-6000,6000); return true
end
function MCP:SetMode(mode)
 mode=string.upper(tostring(mode)); if not VALID[mode] then return false,"invalid_mcp_mode" end
 local x=self.state:Get(); x.Autopilot.Mode=mode
 if mode=="OFF" then x.Autopilot.Enabled=false end
 return true
end
function MCP:Step(dt)
 return true
end
return MCP
