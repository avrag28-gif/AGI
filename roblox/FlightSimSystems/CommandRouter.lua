-- FlightSim server command router v2.1
local Config=require(script.Parent.Config)
local CommandRouter={}; CommandRouter.__index=CommandRouter
local ALLOWED={Battery=true,ExternalPower=true,APU=true,EngineStarter=true,EngineFuel=true,EngineIgnition=true,Throttle=true,Control=true,Flap=true,Gear=true,ParkingBrake=true,ToeBrake=true,NoseWheelSteering=true,AP=true,APTarget=true,NavMode=true,VNAVMode=true,FMCPage=true,FMCScratchpad=true,FMCRoute=true,RadioFrequency=true,TransponderCode=true,TransponderMode=true,TransponderIdent=true,WeatherRadar=true,MCPHeading=true,MCPAltitude=true,MCPMode=true,MCPspeed=true,MCPSpeed=true,MCPVerticalSpeed=true,AutoThrottle=true,ApproachRunway=true,Trim=true,ReverseThrust=true,GoAround=true,VORCourse=true,FuelPump=true,FuelCrossfeed=true,EngineFuelFeed=true,ATCCallsign=true,ATCPhase=true,ATCRequest=true,ATCReadback=true,ATCTakeoffRequest=true,ATCLandingRequest=true,ATCEnterRunway=true,ATCReleaseRunway=true}
local CONTROL_AXES={Aileron=true,Elevator=true,Rudder=true}
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
local function engineIndex(v) local i=tonumber(v); if i~=1 and i~=2 then return nil end return i end
function CommandRouter.new(registry,getFMC,getRadio,getTransponder,getMCP,getApproach,getAutoThrottle,getATC,getATCRunway) return setmetatable({registry=registry,getFMC=getFMC,getRadio=getRadio,getTransponder=getTransponder,getMCP=getMCP,getApproach=getApproach,getAutoThrottle=getAutoThrottle,getATC=getATC,getATCRunway=getATCRunway,lastCommand={}},CommandRouter) end
function CommandRouter:_rateOK(p) local now=os.clock(); local key=p.UserId; local r=self.lastCommand[key]; if not r then self.lastCommand[key]={t=now,n=1}; return true end; if now-r.t>=1 then r.t=now; r.n=1; return true end; if r.n>=(tonumber(Config.CommandRateLimit) or 30) then return false end; r.n+=1; return true end
function CommandRouter:Handle(player,id,command,a,b)
 if type(command)~="string" or not ALLOWED[command] then return false,"command_not_allowed" end
 if not self:_rateOK(player) then return false,"rate_limited" end
 if self.registry:GetOwner(id)~=player then return false,"aircraft_not_owned" end
 local state=self.registry:Get(id); if not state then return false,"aircraft_not_found" end; local x=state:Get()
 if command=="Battery" then x.Electrical.Battery=a==true
 elseif command=="ExternalPower" then x.Electrical.ExternalPower=a==true
 elseif command=="APU" then x.Electrical.APU=a==true
 elseif command=="FuelPump" then local p=string.upper(tostring(a)); local on=b==true; if p=="LEFT" then x.FuelSystem.LeftPumpSwitch=on elseif p=="CENTER" then x.FuelSystem.CenterPumpSwitch=on elseif p=="RIGHT" then x.FuelSystem.RightPumpSwitch=on else return false,"invalid_fuel_pump" end
 elseif command=="FuelCrossfeed" then x.FuelSystem.CrossfeedSwitch=a==true
 elseif command=="EngineFuelFeed" then local i=engineIndex(a); local source=string.upper(tostring(b)); if not i then return false,"invalid_engine" end; if source~="AUTO" and source~="LEFT" and source~="CENTER" and source~="RIGHT" then return false,"invalid_fuel_source" end; x.FuelSystem.EngineFeed[i]=source
 elseif command=="EngineStarter" or command=="EngineFuel" or command=="EngineIgnition" then local i=engineIndex(a); if not i then return false,"invalid_engine" end; local e=x.Engines[i]; if command=="EngineStarter" then e.Starter=b==true elseif command=="EngineFuel" then e.FuelOn=b==true else e.Ignition=b==true end
 elseif command=="Throttle" then local i=engineIndex(a); local v=tonumber(b); if not i or not finite(v) then return false,"invalid_throttle" end; x.Throttle[i]=math.clamp(v,0,1)
 elseif command=="Control" then local axis=tostring(a); local v=tonumber(b); if not CONTROL_AXES[axis] then return false,"invalid_control_axis" end; if not finite(v) then return false,"invalid_control_value" end; x.Controls[axis]=math.clamp(v,-1,1)
 elseif command=="Flap" then local v=tonumber(a); if not finite(v) then return false,"invalid_flap" end; x.Controls.Flap=math.clamp(v,0,1)
 elseif command=="Gear" then x.Gear.Nose,x.Gear.Left,x.Gear.Right=a==true,a==true,a==true
 elseif command=="ParkingBrake" then x.Brakes.Parking=a==true
 elseif command=="ToeBrake" then local v=tonumber(a); if not finite(v) then return false,"invalid_toe_brake" end; x.Brakes.ToeBrake=math.clamp(v,0,1)
 elseif command=="NoseWheelSteering" then local v=tonumber(a); if not finite(v) then return false,"invalid_nose_wheel_steering" end; x.Controls.NoseWheelSteering=math.clamp(v,-1,1)
 elseif command=="ReverseThrust" then local v=tonumber(a); if not finite(v) then return false,"invalid_reverse_thrust" end; x.ReverseThrust=math.clamp(v,0,1); for i=1,2 do x.Engines[i].Reverse=x.ReverseThrust>0 end
 elseif command=="GoAround" then local at=self.getAutoThrottle and self.getAutoThrottle(id); if a==true then x.Autopilot.GoAround=true; x.Landing.GoAround=true; x.Navigation.Mode="HDG"; x.VNAV.Mode="OFF"; x.Autopilot.GoAroundHeading=x.Heading; x.Autopilot.GoAroundAltitude=math.max(x.Autopilot.TargetAltitude or 0,x.Altitude+1000); x.Autopilot.TargetHeading=x.Heading; x.Autopilot.TargetAltitude=x.Autopilot.GoAroundAltitude; if at then at:GoAround() end else x.Autopilot.GoAround=false; x.Landing.GoAround=false; x.Autopilot.GoAroundHeading=nil; x.Autopilot.GoAroundAltitude=nil; if at then at:SetEnabled(false) end end
 elseif command=="VORCourse" then local c=tonumber(a); if not finite(c) then return false,"invalid_vor_course" end; x.Navigation.VORCourse=(c%360+360)%360
 elseif command=="AP" then x.Autopilot.Enabled=a==true
 elseif command=="APTarget" then local alt,hdg=tonumber(a),tonumber(b); if alt and not finite(alt) then return false,"invalid_altitude" end; if hdg and not finite(hdg) then return false,"invalid_heading" end; if alt then x.Autopilot.TargetAltitude=math.clamp(alt,0,60000) end; if hdg then x.Autopilot.TargetHeading=(hdg%360+360)%360 end
 elseif command=="NavMode" then local m=string.upper(tostring(a)); if m~="HDG" and m~="LNAV" and m~="APP" and m~="VOR" then return false,"invalid_nav_mode" end; x.Navigation.Mode=m
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
 elseif command=="MCPspeed" or command=="MCPSpeed" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetSpeed(a)
 elseif command=="MCPVerticalSpeed" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetVerticalSpeed(a)
 elseif command=="MCPMode" then local m=self.getMCP and self.getMCP(id); if not m then return false,"mcp_not_found" end; return m:SetMode(a)
 elseif command=="AutoThrottle" then local at=self.getAutoThrottle and self.getAutoThrottle(id); if not at then return false,"autothrottle_not_found" end; return at:SetEnabled(a==true)
 elseif command=="ApproachRunway" then local ap=self.getApproach and self.getApproach(id); if not ap then return false,"approach_not_found" end; return ap:SetRunway(a)
 elseif command=="Trim" then local v=tonumber(a); if not finite(v) then return false,"invalid_trim" end; x.Controls.Trim=math.clamp(v,-1,1)
 elseif command=="ATCCallsign" then local at=self.getATC and self.getATC(id); if not at then return false,"atc_not_found" end; return at:SetCallsign(a)
 elseif command=="ATCPhase" then local at=self.getATC and self.getATC(id); if not at then return false,"atc_not_found" end; return at:SetPhase(a)
 elseif command=="ATCRequest" then local at=self.getATC and self.getATC(id); if not at then return false,"atc_not_found" end; return at:RequestClearance(a)
 elseif command=="ATCReadback" then local at=self.getATC and self.getATC(id); if not at then return false,"atc_not_found" end; return at:Readback(a)
 elseif command=="ATCTakeoffRequest" or command=="ATCLandingRequest" then local r=self.getATCRunway and self.getATCRunway(id); if not r then return false,"atc_runway_not_found" end; if command=="ATCTakeoffRequest" then return r:RequestTakeoff(a) else return r:RequestLanding(a) end
 elseif command=="ATCEnterRunway" then local r=self.getATCRunway and self.getATCRunway(id); if not r then return false,"atc_runway_not_found" end; return r:EnterRunway()
 elseif command=="ATCReleaseRunway" then local r=self.getATCRunway and self.getATCRunway(id); if not r then return false,"atc_runway_not_found" end; return r:Release() end
 return true
end
return CommandRouter
