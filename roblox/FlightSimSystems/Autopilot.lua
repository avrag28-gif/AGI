-- FlightSim autopilot / VOR / ILS / VNAV controller v1.7
-- Closed-loop game-simulation controller. Values are tuning parameters, not certified aircraft data.
local Autopilot={}; Autopilot.__index=Autopilot
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function err(t,c) return (t-c+540)%360-180 end
local function slew(v,target,rate,dt) local d=target-v; local step=rate*math.max(0,dt); if math.abs(d)<=step then return target end return v+(d>0 and step or -step) end
local function finite(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function firstFinite(...) for i=1,select("#",...) do local v=select(i,...); if finite(v) then return v end end end
local function controlAuthority(state)
 local feel=state.ControlFeel or {}
 local a=clamp(tonumber(feel.AileronAuthority) or 0,0,1)
 local e=clamp(tonumber(feel.ElevatorAuthority) or 0,0,1)
 local r=clamp(tonumber(feel.RudderAuthority) or 0,0,1)
 local hydraulic=clamp(tonumber(feel.HydraulicAuthority) or 0,0,1)
 return a,e,r,hydraulic
end
function Autopilot.new(state) return setmetatable({state=state,bankCommand=0,pitchCommand=0},Autopilot) end
function Autopilot:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local nav=x.Navigation or {}; local v=x.VNAV or {}; local ils=nav.ILS; local vor=nav.VOR
 local altitude=finite(x.Altitude) and x.Altitude or 0; local heading=finite(x.Heading) and x.Heading%360 or 0; local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0)
 ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false; ap.SpeedError=0; ap.SpeedCommand=nil
 local envelope=x.FlightEnvelope or {}; local aAuthority,eAuthority,rAuthority,hydraulicAuthority=controlAuthority(x)
 ap.AileronAuthority=aAuthority; ap.ElevatorAuthority=eAuthority; ap.RudderAuthority=rAuthority; ap.ControlAuthority=math.min(aAuthority,eAuthority,rAuthority); ap.HydraulicAuthority=hydraulicAuthority
 -- A stall is a physical-envelope condition, not an altitude-hold command.
 if ap.Enabled and (x.StallActive==true or envelope.StallActive==true) and not ap.GoAround then
  ap.Enabled=false; ap.DisconnectReason="STALL_ACTIVE"; ap.Mode="DISENGAGED"
  self.bankCommand=0; self.pitchCommand=0
  ap.CommandBank=0; ap.CommandPitch=0; ap.CommandAileron=0; ap.CommandElevator=0
  return true
 end
 if ap.GoAround then
  nav.Mode="HDG"; v.Mode="OFF"; if ils then ils.LocalizerCaptured=false; ils.GlideSlopeCaptured=false end
  ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false; ap.Mode="GO_AROUND"
  local targetH=finite(ap.GoAroundHeading) and ap.GoAroundHeading%360 or (heading+180)%360; local baseAltitude=finite(ap.GoAroundAltitude) and ap.GoAroundAltitude or altitude; local targetA=math.max(baseAltitude,altitude+1000)
  ap.TargetHeading=targetH; ap.TargetAltitude=targetA
  local he=err(targetH,heading); local ae=targetA-altitude
  self.bankCommand=slew(self.bankCommand,clamp(he/30,-0.65,0.65),1.8,dt); self.pitchCommand=slew(self.pitchCommand,clamp(ae/1200,-0.40,0.40),1.5,dt)
  ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand
  ap.AuthorityLimited=aAuthority<0.75 or eAuthority<0.75 or hydraulicAuthority<0.75
  return true
 end
 if not ap.Enabled then
  self.bankCommand=slew(self.bankCommand,0,2.5,dt); self.pitchCommand=slew(self.pitchCommand,0,2.5,dt); ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand; ap.Mode="OFF"; return true
 end
 local mode=nav.Mode
 local appReady=mode=="APP" and ils and ils.Available and ils.LocalizerValid and nav.NAV1Receiver=="ILS"
 if appReady then
  ap.ILSLocalizerCaptured=ils.LocalizerCaptured==true; ap.ILSGlideSlopeCaptured=ils.GlideSlopeCaptured==true and ap.ILSLocalizerCaptured
  if ap.ILSGlideSlopeCaptured then ap.Mode="APP_GS" elseif ap.ILSLocalizerCaptured then ap.Mode="APP_LOC" else ap.Mode="APP_ARMED" end
 elseif mode=="VOR" and vor and vor.Available and nav.NAV1Receiver=="VOR" then ap.Mode="VOR"
 elseif v.Mode=="VNAV" then ap.Mode="VNAV"
 elseif mode=="LNAV" then ap.Mode="LNAV"
 elseif mode=="ALT_HOLD" then ap.Mode="ALT_HOLD"
 elseif mode=="LCHG" then ap.Mode="LCHG"
 elseif mode=="VS" then ap.Mode="VS"
 else ap.Mode="HDG" end
 local targetH=firstFinite(nav.CommandHeading,ap.TargetHeading,heading)%360
 local targetA=firstFinite(v.Mode=="VNAV" and v.TargetAltitude or nil,nav.CommandAltitude,ap.TargetAltitude,altitude)
 if ap.Mode=="APP_GS" or ap.Mode=="APP_LOC" or ap.Mode=="APP_ARMED" then targetH=firstFinite(nav.CommandHeading,heading)%360 end
 local targetSpeed=firstFinite(v.Mode=="VNAV" and v.TargetSpeed or nil,ap.TargetSpeed)
 if finite(targetSpeed) then targetSpeed=clamp(targetSpeed,60,350); ap.SpeedError=targetSpeed-speed; ap.SpeedCommand=targetSpeed end
 local he=err(targetH,heading)
 local bankLimit=(ap.Mode=="APP_GS" or ap.Mode=="APP_LOC") and 0.75 or 0.65
 local bankGain=(ap.Mode=="APP_GS" or ap.Mode=="APP_LOC") and 1/12 or 1/30
 local targetBank=clamp(he*bankGain,-bankLimit,bankLimit)
 if ap.Mode=="APP_LOC" or ap.Mode=="APP_GS" then
  local loc=finite(ils and ils.Localizer) and ils.Localizer or 0
  targetBank=clamp(loc*1.8,-bankLimit,bankLimit)
 elseif ap.Mode=="APP_ARMED" then
  targetBank=clamp(he/30,-bankLimit,bankLimit)
 end
 local altitudeError=targetA-altitude
 local pitchLimit=(ap.Mode=="APP_GS") and 0.32 or 0.45
 local targetPitch
 if ap.Mode=="VS" then targetPitch=clamp((tonumber(ap.TargetVerticalSpeed) or 0)/2500,-pitchLimit,pitchLimit)
 elseif ap.Mode=="ALT_HOLD" then targetPitch=clamp(altitudeError/900,-0.25,0.25)
 elseif ap.Mode=="LCHG" then targetPitch=clamp(altitudeError/1200,-pitchLimit,pitchLimit)
 elseif ap.Mode=="VNAV" then targetPitch=clamp((v.CommandVerticalSpeed or 0)/2500,-pitchLimit,pitchLimit)
 elseif ap.Mode=="APP_GS" then local gsError=finite(ils and ils.GlideSlopeError) and ils.GlideSlopeError or 0; targetPitch=clamp(-gsError/3,-pitchLimit,pitchLimit)
 else targetPitch=clamp(altitudeError/1200,-pitchLimit,pitchLimit) end
 -- Commands remain normalized surface demands. FlightControls is the single
 -- authority gate; applying hydraulic/control authority here as well would
 -- square the authority factor and incorrectly weaken AP response.
 self.bankCommand=slew(self.bankCommand,targetBank,2.2,dt); self.pitchCommand=slew(self.pitchCommand,targetPitch,1.8,dt)
 ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand
 ap.AuthorityLimited=aAuthority<0.75 or eAuthority<0.75 or hydraulicAuthority<0.75
 return true
end
return Autopilot
