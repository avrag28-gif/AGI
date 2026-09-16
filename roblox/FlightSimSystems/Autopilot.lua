-- FlightSim autopilot / VOR / ILS capture / go-around foundation v0.8
-- Closed-loop game-simulation controller. Values are tuning parameters, not certified aircraft data.
local Autopilot={}; Autopilot.__index=Autopilot
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function err(t,c) return (t-c+540)%360-180 end
local function slew(v,target,rate,dt) local d=target-v; local step=rate*math.max(0,dt); if math.abs(d)<=step then return target end; return v+(d>0 and step or -step) end
local function finite(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function firstFinite(...) for i=1,select("#",...) do local v=select(i,...); if finite(v) then return v end end end
function Autopilot.new(state) return setmetatable({state=state,bankCommand=0,pitchCommand=0},Autopilot) end
function Autopilot:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local nav=x.Navigation or {}; local v=x.VNAV or {}; local ils=nav.ILS; local vor=nav.VOR
 local altitude=finite(x.Altitude) and x.Altitude or 0; local heading=finite(x.Heading) and x.Heading%360 or 0
 ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false
 if not ap.Enabled then ap.GoAround=false; self.bankCommand=slew(self.bankCommand,0,2.5,dt); self.pitchCommand=slew(self.pitchCommand,0,2.5,dt); ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand; ap.Mode="OFF"; return true end
 if ap.GoAround then
  nav.Mode="HDG"; v.Mode="OFF"; if ils then ils.LocalizerCaptured=false; ils.GlideSlopeCaptured=false end
  ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false; ap.Mode="GO_AROUND"
  local targetH=finite(ap.GoAroundHeading) and ap.GoAroundHeading%360 or heading; local baseAltitude=finite(ap.GoAroundAltitude) and ap.GoAroundAltitude or altitude; local targetA=math.max(baseAltitude,altitude+1000)
  ap.TargetHeading=targetH; ap.TargetAltitude=targetA; local he=err(targetH,heading); local ae=targetA-altitude
  self.bankCommand=slew(self.bankCommand,clamp(he/30,-0.65,0.65),1.8,dt); self.pitchCommand=slew(self.pitchCommand,clamp(ae/1200,-0.40,0.40),1.5,dt)
  ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand; return true
 end
 local targetH=firstFinite(nav.CommandHeading,ap.TargetHeading,heading)%360
 local targetA=firstFinite(v.Mode=="VNAV" and v.TargetAltitude or nil,nav.CommandAltitude,ap.TargetAltitude,altitude)
 local mode=nav.Mode
 if mode=="APP" and ils and ils.Available and ils.LocalizerValid and nav.NAV1Receiver=="ILS" then
  ap.ILSLocalizerCaptured=ils.LocalizerCaptured==true; ap.ILSGlideSlopeCaptured=ils.GlideSlopeCaptured==true and ap.ILSLocalizerCaptured; targetH=firstFinite(nav.CommandHeading,heading)%360
  if ils.GlideSlopeValid then targetA=firstFinite(nav.CommandAltitude,ils.DesiredAltitude,targetA) end
  if ap.ILSGlideSlopeCaptured then ap.Mode="APP_GS" elseif ap.ILSLocalizerCaptured then ap.Mode="APP_LOC" else ap.Mode="APP_ARMED" end
 elseif mode=="VOR" and vor and vor.Available and nav.NAV1Receiver=="VOR" then
  ap.Mode="VOR"
 elseif v.Mode=="VNAV" then ap.Mode="VNAV"
 elseif mode=="LNAV" then ap.Mode="LNAV"
 elseif mode=="ALT_HOLD" then ap.Mode="ALT_HOLD"
 elseif mode=="LCHG" then ap.Mode="LCHG"
 elseif mode=="VS" then ap.Mode="VS"
 else ap.Mode="HDG" end
 local he=err(targetH,heading); local altitudeError=targetA-altitude; local app=ap.Mode=="APP_GS" or ap.Mode=="APP_LOC" or (mode=="APP" and ils and ils.Available)
 local bankLimit=app and 0.75 or 0.65; local bankGain=app and 1/12 or 1/30; local targetBank=clamp(he*bankGain,-bankLimit,bankLimit)
 local pitchGain=(app and ap.ILSGlideSlopeCaptured) and 1/500 or 1/1200; local pitchLimit=(app and ap.ILSGlideSlopeCaptured) and 0.32 or 0.45; local targetPitch=clamp(altitudeError*pitchGain,-pitchLimit,pitchLimit)
 if ap.Mode=="VS" then targetPitch=clamp((tonumber(ap.TargetVerticalSpeed) or 0)/2500,-pitchLimit,pitchLimit) elseif ap.Mode=="ALT_HOLD" and math.abs(altitudeError)<40 then targetPitch=clamp(-(tonumber(x.VerticalSpeed) or 0)/1800,-0.20,0.20) end
 self.bankCommand=slew(self.bankCommand,targetBank,2.2,dt); self.pitchCommand=slew(self.pitchCommand,targetPitch,1.8,dt); ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand; ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand; return true
end
return Autopilot
