-- FlightSim approach / ILS signal and guidance producer v0.7
-- Simulation approximation; runway references are supplied by airport data.
-- This module produces the raw ILS candidate. NAVReceiver is the sole NAV1/NAV2 owner.
local Approach={}; Approach.__index=Approach
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function hdgErr(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function finite(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function freqMatch(a,b) return finite(a) and finite(b) and math.abs(a-b)<0.005 end
function Approach.new(state) return setmetatable({state=state,locCaptured=false,gsCaptured=false},Approach) end
function Approach:SetRunway(data)
 if type(data)~="table" or typeof(data.Position)~="Vector3" then return false,"invalid_runway" end
 local frequency=tonumber(data.ILSFrequency or data.LocalizerFrequency)
 local hasILS=frequency~=nil
 if hasILS and (not finite(frequency) or frequency<108 or frequency>117.95) then return false,"invalid_ils_frequency" end
 local x=self.state:Get(); x.Navigation.ApproachRunway={Position=data.Position,Heading=wrap(tonumber(data.Heading) or 0),Elevation=tonumber(data.Elevation) or 0,GlideSlope=tonumber(data.GlideSlope) or 3,LocalizerLength=math.max(1000,tonumber(data.LocalizerLength) or 20000),ILSFrequency=frequency,ILSIdent=tostring(data.ILSIdent or "")}
 self.locCaptured=false; self.gsCaptured=false
 return true
end
function Approach:Step(dt)
 local x=self.state:Get(); local n=x.Navigation; local r=n.ApproachRunway
 local tuned=tonumber(x.Radios and x.Radios.NAV1)
 local receiverPowered=x.Avionics and x.Avionics.Radios==true
 if not r then
  n.ILS=nil; self.locCaptured=false; self.gsCaptured=false; return true
 end
 local frequencyValid=r.ILSFrequency and freqMatch(tuned,r.ILSFrequency)
 local ilsAvailable=receiverPowered and frequencyValid
 if not ilsAvailable then
  n.ILS={Available=false,LocalizerValid=false,GlideSlopeValid=false,LocalizerCaptured=false,GlideSlopeCaptured=false,Distance=0,Bearing=0,CourseError=0,DesiredAltitude=nil,FrontCourse=false,Mode="NO_SIGNAL",TunedFrequency=tuned,RequiredFrequency=r.ILSFrequency,Ident=r.ILSIdent}
  self.locCaptured=false; self.gsCaptured=false
  return true
 end
 local dx,dz=x.Position.X-r.Position.X,x.Position.Z-r.Position.Z; local course=math.rad(r.Heading)
 local along=dx*math.sin(course)+dz*math.cos(course)
 local lateral=dx*math.cos(course)-dz*math.sin(course)
 local horizontal=dist(x.Position,r.Position)
 local front=along<0
 local range=math.max(r.LocalizerLength,1)
 local localizer=clamp(-lateral/range,-1,1)
 local desiredAlt=r.Elevation+math.tan(math.rad(r.GlideSlope))*math.max(-along,0)
 local verticalScale=math.max(50,horizontal*0.03)
 local gsError=clamp((x.Altitude-desiredAlt)/verticalScale,-1,1)
 local locValid=front and horizontal<=range
 local gsValid=front and horizontal<=range*1.25
 local captureLoc=math.abs(localizer)<=0.12 and locValid
 local captureGs=math.abs(gsError)<=0.12 and gsValid and self.locCaptured
 if not locValid or math.abs(localizer)>0.22 then self.locCaptured=false elseif captureLoc then self.locCaptured=true end
 if not gsValid or math.abs(gsError)>0.22 or not self.locCaptured then self.gsCaptured=false elseif captureGs then self.gsCaptured=true end
 local ils={Available=true,Localizer=localizer,GlideSlope=gsError,Distance=horizontal,Bearing=wrap(math.deg(math.atan2(r.Position.X-x.Position.X,r.Position.Z-x.Position.Z))),CourseError=hdgErr(r.Heading,x.Heading),DesiredAltitude=desiredAlt,LocalizerValid=locValid,GlideSlopeValid=gsValid,LocalizerCaptured=self.locCaptured,GlideSlopeCaptured=self.gsCaptured,FrontCourse=front,Mode="ARMED",TunedFrequency=tuned,RequiredFrequency=r.ILSFrequency,Ident=r.ILSIdent}
 n.ILS=ils
 if n.Mode=="APP" and locValid then
  n.ILS.Mode=self.locCaptured and (self.gsCaptured and "GS_CAPTURE" or "LOC_CAPTURE") or "CAPTURE"
  local intercept=clamp(localizer*28,-28,28)
  n.CommandHeading=wrap(r.Heading-intercept)
  if gsValid then n.CommandAltitude=desiredAlt end
 else
  n.ILS.Mode="ARMED"
 end
 return true
end
return Approach
