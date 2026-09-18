-- FlightSim 737-style MCP mode panel foundation v0.2
-- Simulation approximation; mode coupling is intentionally explicit and testable.
local MCP={}; MCP.__index=MCP
local VALID={HDG=true,LNAV=true,VNAV=true,APP=true,ALT_HOLD=true,LCHG=true,VS=true,OFF=true}
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function navModeFor(mode)
	if mode=="LNAV" then return "LNAV" end
	if mode=="APP" then return "APP" end
	if mode=="HDG" or mode=="VOR" then return mode end
	return nil
end
function MCP.new(state) return setmetatable({state=state},MCP) end
function MCP:SetHeading(v)
	v=tonumber(v); if not finite(v) then return false,"invalid_heading" end
	local x=self.state:Get(); local h=(v%360+360)%360; x.Autopilot.TargetHeading=h; x.MCP.Heading=h; return true
end
function MCP:SetAltitude(v)
	v=tonumber(v); if not finite(v) then return false,"invalid_altitude" end
	local x=self.state:Get(); local a=math.clamp(v,0,60000); x.Autopilot.TargetAltitude=a; x.MCP.Altitude=a; return true
end
function MCP:SetSpeed(v)
	v=tonumber(v); if not finite(v) then return false,"invalid_speed" end
	local x=self.state:Get(); local s=math.clamp(v,60,350); x.Autopilot.TargetSpeed=s; x.MCP.Speed=s; return true
end
function MCP:SetVerticalSpeed(v)
	v=tonumber(v); if not finite(v) then return false,"invalid_vertical_speed" end
	local x=self.state:Get(); local vs=math.clamp(v,-6000,6000); x.Autopilot.TargetVerticalSpeed=vs; x.MCP.VerticalSpeed=vs; return true
end
function MCP:SetMode(mode)
	mode=string.upper(tostring(mode)); if not VALID[mode] then return false,"invalid_mcp_mode" end
	local x=self.state:Get(); x.Autopilot.Mode=mode; x.MCP.HeadingMode=(mode=="HDG" or mode=="LNAV") and mode.." SEL" or x.MCP.HeadingMode; x.MCP.AltitudeMode=(mode=="ALT_HOLD" or mode=="VNAV" or mode=="LCHG") and mode or x.MCP.AltitudeMode; x.MCP.VerticalSpeedMode=(mode=="VS") and "VS" or x.MCP.VerticalSpeedMode
	if mode=="OFF" then
		x.Autopilot.Enabled=false; x.Navigation.Mode="HDG"; x.VNAV.Mode="OFF"; return true
	end
	x.Autopilot.Enabled=true
	local navMode=navModeFor(mode); if navMode then x.Navigation.Mode=navMode end
	x.VNAV.Mode=(mode=="VNAV") and "VNAV" or "OFF"
	return true
end
function MCP:Step(dt)
	local x=self.state:Get(); local ap=x.Autopilot or {}; local nav=x.Navigation or {}; local v=x.VNAV or {}
	if not ap.Enabled then return end
	if ap.Mode=="HDG" or ap.Mode=="LNAV" then nav.CommandHeading=ap.TargetHeading
	elseif ap.Mode=="APP" then nav.Mode="APP"
	elseif ap.Mode=="VOR" then nav.Mode="VOR" end
	if ap.Mode=="VNAV" then v.Mode="VNAV"
	elseif ap.Mode=="ALT_HOLD" or ap.Mode=="LCHG" or ap.Mode=="VS" then nav.CommandAltitude=ap.TargetAltitude end
	if ap.Mode=="VS" then nav.CommandVerticalSpeed=ap.TargetVerticalSpeed or 0 end
	if ap.Mode=="VNAV" then nav.CommandVerticalSpeed=v.CommandVerticalSpeed end
end
return MCP
