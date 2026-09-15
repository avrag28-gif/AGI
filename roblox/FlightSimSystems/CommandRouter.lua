-- FlightSim server command router v0.2
local CommandRouter = {}
CommandRouter.__index = CommandRouter

local ALLOWED = {
	Battery=true,ExternalPower=true,APU=true,EngineStarter=true,EngineFuel=true,EngineIgnition=true,
	Throttle=true,Control=true,Flap=true,Gear=true,ParkingBrake=true,AP=true,APTarget=true,
	NavMode=true,VNAVMode=true,FMCPage=true,FMCScratchpad=true,FMCRoute=true,
	RadioFrequency=true,TransponderCode=true,WeatherRadar=true,
}

local function finite(n) return n and n == n and n > -math.huge and n < math.huge end

function CommandRouter.new(registry)
	return setmetatable({registry=registry,lastCommand={}},CommandRouter)
end

function CommandRouter:_allowed(player,id) return self.registry:GetOwner(id)==player end

function CommandRouter:Handle(player,id,command,a,b)
	if type(command)~="string" or not ALLOWED[command] then return false,"command_not_allowed" end
	if not self:_allowed(player,id) then return false,"aircraft_not_owned" end
	local state=self.registry:Get(id)
	if not state then return false,"aircraft_not_found" end
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
	elseif command=="APTarget" then x.Autopilot.TargetAltitude=math.max(0,tonumber(a) or x.Autopilot.TargetAltitude); x.Autopilot.TargetHeading=(tonumber(b) or x.Autopilot.TargetHeading)%360
	elseif command=="NavMode" then local m=tostring(a); if m=="HDG" or m=="LNAV" then x.Navigation.Mode=m else return false,"invalid_nav_mode" end
	elseif command=="VNAVMode" then local m=tostring(a); if m=="VNAV" or m=="OFF" then x.Navigation.Mode=(m=="VNAV" and "LNAV" or x.Navigation.Mode); x.VNAV.Mode=m else return false,"invalid_vnav_mode" end
	elseif command=="FMCPage" then x.FMC.Page=tostring(a):sub(1,32)
	elseif command=="FMCScratchpad" then x.FMC.Scratchpad=tostring(a):sub(1,80)
	elseif command=="FMCRoute" then
		if type(a)~="table" then return false,"invalid_route" end
		x.FMC.Route=a; x.FMC.Active=true; x.Navigation.Route=a; x.Navigation.ActiveWaypoint=1
	elseif command=="RadioFrequency" then
		local name=tostring(a); local f=tonumber(b)
		if not finite(f) or f<100 or f>1000 then return false,"invalid_frequency" end
		x.Radios=x.Radios or {}; x.Radios[name]=f
	elseif command=="TransponderCode" then
		local code=tostring(a); if not code:match("^%d%d%d%d$") then return false,"invalid_transponder" end; x.TransponderCode=code
	elseif command=="WeatherRadar" then x.Avionics.WeatherRadarEnabled=a==true
	end
	return true
end

return CommandRouter
