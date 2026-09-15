-- FlightSim approach / ILS guidance foundation v0.3
-- Runway references are supplied by airport data; this module does not invent an airport.
local Approach={}; Approach.__index=Approach
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function hdgErr(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
function Approach.new(state) return setmetatable({state=state},Approach) end
function Approach:SetRunway(data)
 if type(data)~="table" or typeof(data.Position)~="Vector3" then return false,"invalid_runway" end
 local x=self.state:Get(); x.Navigation.ApproachRunway={Position=data.Position,Heading=wrap(tonumber(data.Heading) or 0),Elevation=tonumber(data.Elevation) or 0,GlideSlope=tonumber(data.GlideSlope) or 3,LocalizerLength=tonumber(data.LocalizerLength) or 20000}; return true
end
function Approach:Step(dt)
 local x=self.state:Get(); local n=x.Navigation; local r=n.ApproachRunway; if not r then n.ILS=nil; return end
 local dx,dz=x.Position.X-r.Position.X,x.Position.Z-r.Position.Z; local course=math.rad(r.Heading)
 local along=dx*math.sin(course)+dz*math.cos(course); local lateral=dx*math.cos(course)-dz*math.sin(course); local horizontal=dist(x.Position,r.Position)
 local front=along<0; local localizer=clamp(-lateral/math.max(r.LocalizerLength,1),-1,1)
 local desiredAlt=r.Elevation+math.tan(math.rad(r.GlideSlope))*math.max(-along,0)
 local gsError=clamp((x.Altitude-desiredAlt)/math.max(50,horizontal*0.03),-1,1)
 local locValid=front and horizontal<=r.LocalizerLength and math.abs(localizer)<=1; local gsValid=front and horizontal<=r.LocalizerLength*1.25 and math.abs(gsError)<=1
 n.ILS={Available=locValid,Localizer=localizer,GlideSlope=gsError,Distance=horizontal,Bearing=wrap(math.deg(math.atan2(r.Position.X-x.Position.X,r.Position.Z-x.Position.Z))),CourseError=hdgErr(r.Heading,x.Heading),DesiredAltitude=desiredAlt,LocalizerValid=locValid,GlideSlopeValid=gsValid,LocalizerCaptured=math.abs(localizer)<0.12 and locValid,GlideSlopeCaptured=math.abs(gsError)<0.12 and gsValid}
 local mode=n.Mode; n.ILS.Mode=(mode=="APP" and locValid) and "CAPTURE" or "ARMED"
 if mode=="APP" and locValid then
  n.CommandHeading=wrap(r.Heading-localizer*25)
  if gsValid then n.CommandAltitude=desiredAlt end
 else n.CommandHeading=x.Autopilot and x.Autopilot.TargetHeading or x.Heading end
end
return Approach
