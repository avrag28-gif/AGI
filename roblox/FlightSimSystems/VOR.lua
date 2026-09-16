-- FlightSim VOR receiver / radial guidance foundation v0.5
-- NAV1 and NAV2 are independent receiver paths. DME is geometric simulation data.
local VOR={}; VOR.__index=VOR
local function wrap(v) return (v%360+360)%360 end
local function err(t,c) return (t-c+540)%360-180 end
local function dist(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function bearing(a,b) return wrap(math.deg(math.atan2(b.X-a.X,b.Z-a.Z))) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function freqMatch(a,b) return finite(a) and finite(b) and math.abs(a-b)<0.005 end
local function clearReceiver(n,index)
 local p="NAV"..tostring(index); n[p.."Receiver"]="NONE"; n[p.."Ident"]=nil; n[p.."Frequency"]=nil; n[p.."Signal"]=nil
end
local function solve(n,x,station,index,course)
 local p="NAV"..tostring(index); local frequency=tonumber(x.Radios and x.Radios[p])
 if not station or not freqMatch(frequency,station.Frequency) then
  n[p.."Signal"]=nil
  if n[p.."Receiver"]=="VOR" then clearReceiver(n,index) end
  return nil
 end
 n[p.."Receiver"]="VOR"; n[p.."Ident"]=station.Ident; n[p.."Frequency"]=station.Frequency
 local distance=dist(x.Position,station.Position); local toStation=bearing(x.Position,station.Position); local radial=wrap(toStation+180); local selected=wrap(tonumber(course) or radial); local courseError=err(selected,radial); local angle=math.abs(err(selected,toStation)); local to=angle<=90
 local dme=station.DME==true
 n[p.."Signal"]={Available=true,Source="VOR",Ident=station.Ident,Frequency=station.Frequency,Distance=distance,DMEDistanceNM=dme and distance/1852 or nil,DMEAvailable=dme,BearingToStation=toStation,Radial=radial,Course=selected,CourseError=courseError,TO=to,FROM=not to}
 return n[p.."Signal"]
end
function VOR.new(state) return setmetatable({state=state},VOR) end
function VOR:SetStation(data,receiver)
 if type(data)~="table" or typeof(data.Position)~="Vector3" then return false,"invalid_vor_station" end
 local frequency=tonumber(data.Frequency); if not finite(frequency) or frequency<108 or frequency>117.95 then return false,"invalid_vor_frequency" end
 receiver=string.upper(tostring(receiver or "NAV1")); if receiver~="NAV1" and receiver~="NAV2" then return false,"invalid_vor_receiver" end
 local x=self.state:Get(); local key=receiver=="NAV2" and "VORStationNAV2" or "VORStation"; x.Navigation[key]={Position=data.Position,Frequency=frequency,Ident=tostring(data.Ident or "VOR"),DME=data.DME==true}; return true
end
function VOR:SetCourse(course,receiver)
 local x=self.state:Get(); local n=x.Navigation; local c=tonumber(course); if not finite(c) then return false,"invalid_vor_course" end
 receiver=string.upper(tostring(receiver or "NAV1")); if receiver=="NAV2" then n.VORCourseNAV2=wrap(c) elseif receiver=="NAV1" then n.VORCourse=wrap(c) else return false,"invalid_vor_receiver" end
 return true
end
function VOR:Step(dt)
 local x=self.state:Get(); local n=x.Navigation
 -- NAV1 is shared with ILS, so ILS ownership suppresses VOR1.
 if n.NAV1Receiver=="ILS" then n.VOR=nil; n.NAV1Signal=nil else n.VOR=solve(n,x,n.VORStation,1,n.VORCourse) end
 -- NAV2 is independent and is not contested by the ILS receiver.
 n.VOR2=solve(n,x,n.VORStationNAV2,2,n.VORCourseNAV2)
end
return VOR
