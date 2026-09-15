-- FlightSim server command router v0.3
local CommandRouter = {}
CommandRouter.__index = CommandRouter

local ALLOWED={Battery=true,ExternalPower=true,APU=true,EngineStarter=true,EngineFuel=true,EngineIgnition=true,Throttle=true,Control=true,Flap=true,Gear=true,ParkingBrake=true,AP=true,APTarget=true,NavMode=true,VNAVMode=true,FMCPage=true,FMCScratchpad=true,FMCRoute=true,RadioFrequency=true,TransponderCode=true,WeatherRadar=true}
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end

function CommandRouter.new(registry,getFMC)
	return setmetatable({registry=registry,getFMC=getFMC,lastCommand={}},CommandRouter)
end
function CommandRouter:_allowed(player,id) return self.registry:GetOwner(id)==player end

function CommandRouter:Handle(player,id,command,a,b)
	if type(command)~="string" or not ALLOWED[command] then return false,"command_not_allowed" end
	if not self:_allowed(player,id) then return false,"aircraft_not_owned" end
	local state=self.registry:Get(id); if not state then return false,"aircraft_not_found" end
	local x=state:Get()
	if command=="Battery" then x.Electrical.Battery=a==true
	elseif command=="ExternalPower" then x.Electrical.ExternalPower=a==true
	elseif command=="APU" then x.Electrical.APU=a==true
	elseif command=="EngineStarter" or command=="EngineFuel" or command=="EngineIgnition" then
		local i=math.clamp(tonumber(a) or 0,1,2); local e=x.Engines[i]
		if command=="EngineStarter" then e.Starter=b==true elseif command=="EngineFuel" then e.FuelOn=b==true else e.Ignition=b==true end
	elseif command=="Throttle" then local i=math.clamp(tonumber(a) or 0,1,2); x.Throttle[i]=math.clamp(tonumber(b) or 0,0,1)
	elseif command=="Control" then local axis=tostring(a); if x.Controls[axis]~=nil then x.Controls[axis]=math.clamp(tonumber(b) or 0,-1,1) end
	elseif command=="Flap" then x.Controls.Flap=math.clamp(tonumber(a) or 0,0,1)
	elseif command=="Gear" then local d=a==true; x.Gear.Nose,x.Gear.Left,x.Gear.Right=d,d,d
	elseif command=="ParkingBrake" then x.Brakes.Parking=a==true
	elseif command=="AP" then x.Autopilot.Enabled=a==true
	elseif command=="APTarget" then
		local alt,hdg=tonumber(a),tonumber(b); if alt and finite(alt) then x.Autopilot.TargetAltitude=math.clamp(alt,0,60000) end; if hdg and finite(hdg) then x.Autopilot.TargetHeading=hdg%360 end
	elseif command=="NavMode" then local m=string.upper(tostring(a)); if m~="HDG" and m~="LNAV" then return false,"invalid_nav_mode" end; x.Navigation.Mode=m
	elseif command=="VNAVMode" then local m=string.upper(tostring(a)); if m~="VNAV" and m~="OFF" then return false,"invalid_vnav_mode" end; x.VNAV.Mode=m
	elseif command=="FMCPage" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; return f:SetPage(a)
	elseif command=="FMCScratchpad" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; return f:SetScratchpad(a)
	elseif command=="FMCRoute" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; return f:SetRoute(type(a)=="table" and a.Origin or nil,type(a)=="table" and a.Destination or nil,type(a)=="table" and a.Route or nil,type(a)=="table" and a.CruiseAltitude or nil)
	elseif command=="RadioFrequency" then
		local name=string.upper(tostring(a)); local f=tonumber(b); if not finite(f) or f<100 or f>1000 or not name:match("^[A-Z][A-Z0-9_]{0,15}$") then return false,"invalid_frequency" end; x.Radios=x.Radios or {}; x.Radios[name]=f
	elseif command=="TransponderCode" then local code=tostring(a); if not code:match("^[0-7][0-7][0-7][0-7]$") then return false,"invalid_transponder" end; x.TransponderCode=code
	elseif command=="WeatherRadar" then x.Avionics.WeatherRadarEnabled=a==true end
	return true
end
return CommandRouter
