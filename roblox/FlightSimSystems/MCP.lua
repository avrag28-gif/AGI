-- FlightSim 737-style MCP mode panel foundation v0.1
local MCP={}; MCP.__index=MCP
local VALID={HDG=true,LNAV=true,VNAV=true,APP=true,ALT_HOLD=true,LCHG=true,VS=true,OFF=true}
function MCP.new(state) return setmetatable({state=state},MCP) end
function MCP:SetHeading(v)
	v=tonumber(v); if not v or v~=v then return false,"invalid_heading" end
	self.state:Get().Autopilot.TargetHeading=v%360; return true
end
function MCP:SetAltitude(v)
	v=tonumber(v); if not v or v~=v then return false,"invalid_altitude" end
	self.state:Get().Autopilot.TargetAltitude=math.clamp(v,0,60000); return true
end
function MCP:SetMode(mode)
	mode=string.upper(tostring(mode)); if not VALID[mode] then return false,"invalid_mcp_mode" end
	local x=self.state:Get(); x.Autopilot.Mode=mode
	if mode=="OFF" then x.Autopilot.Enabled=false end
	return true
end
function MCP:Step(dt)
	local x=self.state:Get(); local ap=x.Autopilot
	if not ap.Enabled then return end
	if ap.Mode=="HDG" or ap.Mode=="LNAV" then x.Navigation.CommandHeading=ap.TargetHeading end
	if ap.Mode=="VNAV" or ap.Mode=="ALT_HOLD" or ap.Mode=="LCHG" or ap.Mode=="VS" then x.Navigation.CommandAltitude=ap.TargetAltitude end
end
return MCP
