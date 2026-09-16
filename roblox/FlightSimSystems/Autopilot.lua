-- FlightSim autopilot / ILS capture / go-around foundation v0.6
-- Closed-loop game-simulation controller. Values are tuning parameters, not certified aircraft data.
local Autopilot={}; Autopilot.__index=Autopilot
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function err(t,c) return (t-c+540)%360-180 end
local function slew(v,target,rate,dt)
 local d=target-v; local step=rate*math.max(0,dt)
 if math.abs(d)<=step then return target end
 return v+(d>0 and step or -step)
end
function Autopilot.new(state)
 return setmetatable({state=state,bankCommand=0,pitchCommand=0},Autopilot)
end
function Autopilot:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot; local nav=x.Navigation or {}; local v=x.VNAV or {}; local ils=nav.ILS
 ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false
 if not ap.Enabled then
  self.bankCommand=slew(self.bankCommand,0,2.5,dt); self.pitchCommand=slew(self.pitchCommand,0,2.5,dt)
  ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand
  ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand
  ap.Mode="OFF"; return
 end
 if ap.GoAround then
  nav.Mode="HDG"; v.Mode="OFF"
  ap.Mode="GO_AROUND"
  local targetH=ap.TargetHeading or x.Heading
  local targetA=math.max(ap.TargetAltitude or 0,(tonumber(x.Altitude) or 0)+1000)
  ap.TargetAltitude=targetA
  local he=err(targetH,x.Heading); local ae=targetA-x.Altitude
  local targetBank=clamp(he/30,-0.65,0.65)
  local targetPitch=clamp(ae/1200,-0.40,0.40)
  self.bankCommand=slew(self.bankCommand,targetBank,1.8,dt)
  self.pitchCommand=slew(self.pitchCommand,targetPitch,1.5,dt)
  ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand
  ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand
  return
 end
 local targetH=nav.CommandHeading or ap.TargetHeading or x.Heading
 local targetA=(v.Mode=="VNAV" and v.TargetAltitude) or nav.CommandAltitude or ap.TargetAltitude or x.Altitude
 local mode=nav.Mode
 if mode=="APP" and ils and ils.LocalizerValid then
  ap.ILSLocalizerCaptured=ils.LocalizerCaptured==true
  ap.ILSGlideSlopeCaptured=ils.GlideSlopeCaptured==true
  targetH=nav.CommandHeading or x.Heading
  if ils.GlideSlopeValid then targetA=nav.CommandAltitude or x.Altitude end
  if ap.ILSGlideSlopeCaptured then ap.Mode="APP_GS" elseif ap.ILSLocalizerCaptured then ap.Mode="APP_LOC" else ap.Mode="APP_ARMED" end
 elseif v.Mode=="VNAV" then ap.Mode="VNAV"
 elseif mode=="LNAV" then ap.Mode="LNAV"
 elseif mode=="ALT_HOLD" then ap.Mode="ALT_HOLD"
 elseif mode=="LCHG" then ap.Mode="LCHG"
 elseif mode=="VS" then ap.Mode="VS"
 else ap.Mode="HDG" end
 local he=err(targetH,x.Heading)
 local altitudeError=targetA-(tonumber(x.Altitude) or 0)
 local bankLimit=(mode=="APP" and ils and ils.LocalizerValid) and 0.75 or 0.65
 local bankGain=(mode=="APP" and ils and ils.LocalizerValid) and 1/12 or 1/30
 local targetBank=clamp(he*bankGain,-bankLimit,bankLimit)
 local pitchGain=(mode=="APP" and ils and ils.GlideSlopeCaptured) and 1/500 or 1/1200
 local pitchLimit=(mode=="APP" and ils and ils.GlideSlopeCaptured) and 0.32 or 0.45
 local targetPitch=clamp(altitudeError*pitchGain,-pitchLimit,pitchLimit)
 if ap.Mode=="VS" then
  local vsTarget=tonumber(ap.TargetVerticalSpeed) or 0
  targetPitch=clamp(vsTarget/2500,-pitchLimit,pitchLimit)
 elseif ap.Mode=="ALT_HOLD" and math.abs(altitudeError)<40 then
  targetPitch=clamp(-(tonumber(x.VerticalSpeed) or 0)/1800,-0.20,0.20)
 end
 self.bankCommand=slew(self.bankCommand,targetBank,2.2,dt)
 self.pitchCommand=slew(self.pitchCommand,targetPitch,1.8,dt)
 ap.CommandBank=self.bankCommand; ap.CommandPitch=self.pitchCommand
 ap.CommandAileron=self.bankCommand; ap.CommandElevator=self.pitchCommand
 return true
end
return Autopilot
