-- FlightSim VOR receiver / radial guidance foundation v0.2
-- Uses selected course geometry to derive radial, TO/FROM and CDI-style course error.
local VOR={}; VOR.__index=VOR
local function wrap(v) return (v%360+360)%360 end
local function err(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
function VOR.new(state) return setmetatable({state=state},VOR) end
function VOR:SetStation(data)
 if type(data)~="table" or typeof(data.Position)~="Vector3" then return false,"invalid_vor_station" end
 local x=self.state:Get(); x.Navigation.VORStation={Position=data.Position,Frequency=tonumber(data.Frequency) or 0,Ident=tostring(data.Ident or "VOR")}; return true
end
function VOR:SetCourse(course)
 local x=self.state:Get(); local n=x.Navigation; local c=tonumber(course)
 if not c or c~=c or c==-math.huge or c==math.huge then return false,"invalid_vor_course" end
 n.VORCourse=wrap(c); return true
end
function VOR:Step(dt)
 local x=self.state:Get(); local n=x.Navigation; local st=n.VORStation
 if not st then n.VOR=nil; return end
 local frequency=tonumber(x.Radios.NAV1) or 0
 local tuned=math.abs(frequency-(st.Frequency or 0))<0.01
 if not tuned then n.VOR={Available=false}; return end
 local toStation=bearing(x.Position,st.Position)
 local radial=wrap(toStation+180)
 local course=wrap(tonumber(n.VORCourse) or radial)
 local courseError=err(course,radial)
 local angle=math.abs(err(course,toStation))
 local to=angle<=90
 n.VOR={Available=true,Distance=dist(x.Position,st.Position),BearingToStation=toStation,Radial=radial,Course=course,CourseError=courseError,TO=to,FROM=not to,Ident=st.Ident,Frequency=st.Frequency}
end
return VOR
