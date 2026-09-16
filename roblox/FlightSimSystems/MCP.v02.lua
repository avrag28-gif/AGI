-- FlightSim 737-style MCP mode panel foundation v0.3
-- MCP stores pilot-selected targets and synchronizes the navigation mode used by guidance.
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
 if mode=="OFF" then x.Autopilot.Enabled=false; x.Navigation.Mode="HDG"; x.VNAV.Mode="OFF"; return true end
 x.Autopilot.Enabled=true
 if mode=="VNAV" then x.Navigation.Mode="LNAV"; x.VNAV.Mode="VNAV"
 else x.VNAV.Mode="OFF"; x.Navigation.Mode=mode end
 return true
end
function MCP:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local nav=x.Navigation or {}; local v=x.VNAV or {}
 if ap.Enabled and ap.Mode and ap.Mode~="OFF" then
  if ap.Mode=="VNAV" then nav.Mode="LNAV"; v.Mode="VNAV" elseif ap.Mode=="LNAV" or ap.Mode=="VOR" or ap.Mode=="APP" or ap.Mode=="HDG" then nav.Mode=ap.Mode; v.Mode="OFF" end
 end
 return true
end
return MCP
