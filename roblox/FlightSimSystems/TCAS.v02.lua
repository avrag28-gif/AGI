-- FlightSim TCAS-style advisory controller v0.4
-- Game-simulation model; this is not certified ACAS/TCAS II logic.
local TCAS={}; TCAS.__index=TCAS
local NM=1852
local function finite(v,d) v=tonumber(v); if not v or v~=v or v==math.huge or v==-math.huge then return d end; return v end
local function ensure(x)
 x.TCAS=x.TCAS or {Powered=false,Advisories={},ClosestIntruder=nil,ClosestRangeM=nil,HighestLevel="NONE"}
 local t=x.TCAS; t.Advisories=t.Advisories or {}; return t
end
local function classify(rangeM,verticalFt,closingKts)
 local r=finite(rangeM,math.huge); local v=math.abs(finite(verticalFt,math.huge)); local c=math.max(0,finite(closingKts,0))
 if r<=0 or r>5*NM or v>1000 then return nil end
 if r<=0.8*NM and v<=600 and c>=40 then return "RA" end
 if r<=3*NM and v<=850 then return "TA" end
 return nil
end
local function makeAdvisory(state,id,ownId,ownPos,ownAlt,ownVel)
 if id==ownId then return nil end
 local s=state:Get(); local p=s.Position; if typeof(p)~="Vector3" then return nil end
 local d=p-ownPos; local range=d.Magnitude; local vertical=finite(s.Altitude,0)-ownAlt; local horizontal=Vector3.new(d.X,0,d.Z); local h=horizontal.Magnitude; local closing=0
 if h>0.01 and typeof(s.Velocity)=="Vector3" and typeof(ownVel)=="Vector3" then
  local rel=s.Velocity-ownVel; closing=math.max(0,-rel:Dot(horizontal.Unit))*1.94384449
 end
 local level=classify(range,vertical,closing); if not level then return nil end
 return {Intruder=id,RangeM=range,RangeNm=range/NM,VerticalSeparationFt=math.abs(vertical),RelativeAltitudeFt=vertical,ClosingSpeedKts=closing,Level=level,Position=p,Altitude=finite(s.Altitude,0)}
end
function TCAS.new(registry) return setmetatable({registry=registry},TCAS) end
function TCAS:Step(ownId)
 local own=self.registry:Get(ownId); if not own then return {} end
 local ox=own:Get(); local t=ensure(ox); t.Powered=ox.Avionics and ox.Avionics.TCAS==true; t.Advisories={}; t.ClosestIntruder=nil; t.ClosestRangeM=nil; t.HighestLevel="NONE"
 if not t.Powered or typeof(ox.Position)~="Vector3" then return t.Advisories end
 self.registry:ForEach(function(id,state) local a=makeAdvisory(state,id,ownId,ox.Position,finite(ox.Altitude,0),ox.Velocity); if a then t.Advisories[#t.Advisories+1]=a end end)
 table.sort(t.Advisories,function(a,b)return a.RangeM<b.RangeM end)
 local closest=t.Advisories[1]; if closest then t.ClosestIntruder=closest.Intruder; t.ClosestRangeM=closest.RangeM end
 for _,a in ipairs(t.Advisories) do if a.Level=="RA" then t.HighestLevel="RA"; break elseif t.HighestLevel=="NONE" then t.HighestLevel="TA" end end
 return t.Advisories
end
return TCAS
