-- FlightSim autopilot / ILS capture / go-around foundation v0.4
local Autopilot={}; Autopilot.__index=Autopilot
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function err(t,c) return (t-c+540)%360-180 end
function Autopilot.new(state) return setmetatable({state=state},Autopilot) end
function Autopilot:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot; local nav=x.Navigation or {}; local v=x.VNAV or {}; local ils=nav.ILS
 ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false
 if not ap.Enabled then ap.CommandBank=0; ap.CommandPitch=0; ap.CommandAileron=0; ap.CommandElevator=0; ap.Mode="OFF"; return end
 if ap.GoAround then
  nav.Mode="HDG"; v.Mode="OFF"; ap.ILSLocalizerCaptured=false; ap.ILSGlideSlopeCaptured=false
  ap.Mode="GO_AROUND"
  local targetH=ap.TargetHeading or x.Heading
  local targetA=math.max(ap.TargetAltitude or 0,x.Altitude+1000)
  local he=err(targetH,x.Heading); local ae=targetA-x.Altitude
  ap.CommandBank=clamp(he/25,-0.7,0.7)
  ap.CommandPitch=clamp(ae/900,-0.45,0.45)
  ap.CommandAileron=ap.CommandBank; ap.CommandElevator=ap.CommandPitch
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
 elseif v.Mode=="VNAV" then ap.Mode="VNAV" elseif mode=="LNAV" then ap.Mode="LNAV" else ap.Mode="HDG" end
 local he=err(targetH,x.Heading); local ae=targetA-x.Altitude
 local bank=clamp(he/25,-1,1); local pitch=clamp(ae/1000,-0.55,0.55)
 if mode=="APP" and ils and ils.LocalizerValid then bank=clamp(he/12,-1,1) end
 if mode=="APP" and ils and ils.GlideSlopeCaptured then pitch=clamp(ae/350,-0.35,0.35) end
 ap.CommandBank=bank; ap.CommandPitch=pitch; ap.CommandAileron=bank; ap.CommandElevator=pitch
end
return Autopilot
