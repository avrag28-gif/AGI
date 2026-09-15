-- FlightSim server command router v0.6
local Config=require(script.Parent.Config)
local CommandRouter={}; CommandRouter.__index=CommandRouter
local ALLOWED={Battery=true,ExternalPower=true,APU=true,EngineStarter=true,EngineFuel=true,EngineIgnition=true,Throttle=true,Control=true,Flap=true,Gear=true,ParkingBrake=true,AP=true,APTarget=true,NavMode=true,VNAVMode=true,FMCPage=true,FMCScratchpad=true,FMCRoute=true,RadioFrequency=true,TransponderCode=true,TransponderMode=true,TransponderIdent=true,WeatherRadar=true,MCPHeading=true,MCPAltitude=true,MCPMode=true}
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
function CommandRouter.new(registry,getFMC,getRadio,getTransponder,getMCP) return setmetatable({registry=registry,getFMC=getFMC,getRadio=getRadio,getTransponder=getTransponder,getMCP=getMCP,lastCommand={}},CommandRouter) end
function CommandRouter:_allowed(p,id) return self.registry:GetOwner(id)==p end
function CommandRouter:_rateOK(p)
 local now=os.clock(); local key=p.UserId; local r=self.lastCommand[key]
 if not r then self.lastCommand[key]={t=now,n=1}; return true end
 if now-r.t>=1 then r.t=now; r.n=1; return true end
 if r.n >= (tonumber(Config.CommandRateLimit) or 30) then return false end
 r.n+=1; return true
end
function CommandRouter:Handle(player,id,command,a,b)
 if not self:_rateOK(player) then return false,"rate_limited" end
 if type(command)~="string" or not ALLOWED[command] then return false,"command_not_allowed" end
 if not self:_allowed(player,id) then return false,"aircraft_not_owned" end
 local state=self.registry:Get(id); if not state then return false,"aircraft_not_found" end
 local x=state:Get()
 if command=="Battery" then x.Electrical.Battery=a==true
 elseif command=="ExternalPower" then x.Electrical.ExternalPower=a==true
 elseif command=="APU" then x.Electrical.APU=a==true
 elseif command=="EngineStarter" or command=="EngineFuel" or command=="EngineIgnition" then local i=math.clamp(tonumber(a) or 0,1,2); local e=x.Engines[i]; if command=="EngineStarter" then e.Starter=b==true elseif command=="EngineFuel" then e.FuelOn=b==true else e.Ignition=b==true end
 elseif command=="Throttle" then local i=math.clamp(tonumber(a) or 0,1,2); x.Throttle[i]=math.clamp(tonumber(b) or 0,0,1)
 elseif command=="Control" then local axis=tostring(a); if x.Controls[axis]~=nil then x.Controls[axis]=math.clamp(tonumber(b) or 0,-1,1) end
 elseif command=="Flap" then x.Controls.Flap=math.clamp(tonumber(a) or 0,0,1)
 elseif command=="Gear" then local d=a==true; x.Gear.Nose,x.Gear.Left,x.Gear.Right=d,d,d
 elseif command=="ParkingBrake" then x.Brakes.Parking=a==true
 elseif command=="AP" then x.Autopilot.Enabled=a==true
 elseif command=="APTarget" then local alt,hdg=tonumber(a),tonumber(b); if alt and finite(alt) then x.Autopilot.TargetAltitude=math.clamp(alt,0,60000) end; if hdg and finite(hdg) then x.Autopilot.TargetHeading=hdg%360 end
 elseif command=="NavMode" then local m=string.upper(tostring(a)); if m~="HDG" and m~="LNAV" then return false,"invalid_nav_mode" end; x.Navigation.Mode=m
 elseif command=="VNAVMode" then local m=string.upper(tostring(a)); if m~="VNAV" and m~="OFF" then return false,"invalid_vnav_mode" end; x.VNAV.Mode=m
 elseif command=="FMCPage" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; return f:SetPage(a)
 elseif command=="FMCScratchpad" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; return f:SetScratchpad(a)
 elseif command=="FMCRoute" then local f=self.getFMC and self.getFMC(id); if not f then return false,"fmc_not_found" end; if type(a)~="table" then return false,"invalid_route" end; return f:SetRoute(a.Origin,a.Destination,a.Route,a.CruiseAltitude)
 elseif command=="RadioFrequency" then local r=self.getRadio and self.getRadio(id); if not r then return false,"radio_not_found" end; return r:Set(a,b)
 elseif command=="TransponderCode" then local t=self.getTransponder and self.getTransponder(id); if not t then return false,"transponder_not_found" end; return t:SetCode(a)
 elseif command=="TransponderMode" then local t=self.getTransponder and self.getTransponder(id); if not t then return false,"transponder_not_found" end; return t:SetMode(a)
 elseif command=="TransponderIdent" then local t=self.getTransponder and self.getTransponder(id); if not t then return false,"transponder_not_found" end; return t:Ident()
 elseif command=="WeatherRadar" then x.Avionics.WeatherRadarEnabled=a==true
 elseif command=="MCPHeading" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetHeading(a)
 elseif command=="MCPAltitude" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetAltitude(a)
 elseif command=="MCPMode" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetMode(a) end
 return true
end
return CommandRouter
