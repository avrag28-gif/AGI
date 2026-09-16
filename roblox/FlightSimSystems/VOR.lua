-- FlightSim VOR receiver / radial guidance foundation v0.3
-- NAV1 is a single receiver path: VOR only publishes when it owns NAV1.
local VOR={}; VOR.__index=VOR
local function wrap(v) return (v%360+360)%360 end
local function err(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
local function freqMatch(a,b) return type(a)=="number" and a==a and type(b)=="number" and b==b and math.abs(a-b)<0.005 end
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
 local frequency=tonumber(x.Radios and x.Radios.NAV1) or 0
 if n.NAV1Receiver=="ILS" then n.VOR=nil; return end
 if not st or not freqMatch(frequency,st.Frequency) then
  n.VOR=nil
  if n.NAV1Receiver=="VOR" then n.NAV1Receiver="NONE"; n.NAV1Ident=nil; n.NAV1Frequency=nil end
  return
 end
 n.NAV1Receiver="VOR"; n.NAV1Ident=st.Ident; n.NAV1Frequency=st.Frequency
 local toStation=bearing(x.Position,st.Position)
 local radial=wrap(toStation+180)
 local course=wrap(tonumber(n.VORCourse) or radial)
 local courseError=err(course,radial)
 local angle=math.abs(err(course,toStation))
 local to=angle<=90
 n.VOR={Available=true,Distance=dist(x.Position,st.Position),BearingToStation=toStation,Radial=radial,Course=course,CourseError=courseError,TO=to,FROM=not to,Ident=st.Ident,Frequency=st.Frequency}
end
return VOR
