-- FlightSim approach / ILS guidance foundation v0.2
-- Runway references are supplied by airport data; this module does not invent an airport.
local Approach={}; Approach.__index=Approach
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function hdgErr(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
function Approach.new(state) return setmetatable({state=state},Approach) end
function Approach:SetRunway(data)
 if type(data)~="table" or typeof(data.Position)~="Vector3" then return false,"invalid_runway" end
 local x=self.state:Get(); x.Navigation.ApproachRunway={Position=data.Position,Heading=wrap(tonumber(data.Heading) or 0),Elevation=tonumber(data.Elevation) or 0,GlideSlope=tonumber(data.GlideSlope) or 3,LocalizerLength=tonumber(data.LocalizerLength) or 20000}; return true
end
function Approach:Step(dt)
 local x=self.state:Get(); local n=x.Navigation; local r=n.ApproachRunway
 if not r then return end
 local dx,dz=x.Position.X-r.Position.X,x.Position.Z-r.Position.Z
 local course=math.rad(r.Heading); local along=dx*math.sin(course)+dz*math.cos(course); local lateral=dx*math.cos(course)-dz*math.sin(course)
 local horizontal=dist(x.Position,r.Position)
 local desiredAlt=r.Elevation + math.tan(math.rad(r.GlideSlope))*math.max(-along,0)
 n.ILS={Available=true,Localizer=clamp(-lateral/math.max(r.LocalizerLength,1),-1,1),GlideSlope=clamp((x.Altitude-desiredAlt)/math.max(50,horizontal*0.03),-1,1),Distance=horizontal,Bearing=bearing(x.Position,r.Position),CourseError=hdgErr(r.Heading,x.Heading),DesiredAltitude=desiredAlt}
 if n.Mode=="APP" then n.CommandHeading=wrap(r.Heading - n.ILS.Localizer*20); n.CommandAltitude=desiredAlt end
end
return Approach
