-- FlightSim TCAS-style advisory controller v0.2
local TCAS={}; TCAS.__index=TCAS
function TCAS.new(registry) return setmetatable({registry=registry,advisories={}},TCAS) end
local function add(x,id,ownId,ownPos,ownAlt)
 if id==ownId then return end
 local s=x:Get(); local p=s.Position; if typeof(p)~="Vector3" then return end
 local d=(p-ownPos).Magnitude; local v=math.abs((tonumber(s.Altitude) or 0)-ownAlt)
 if d<=5000 and v<=1000 then return {Intruder=id,RangeM=d,VerticalSeparationFt=v,Level=d<=1500 and "RA" or "TA"} end
end
function TCAS:Step(ownId)
 self.advisories={}; local own=self.registry:Get(ownId); if not own then return self.advisories end
 local ox=own:Get(); if ox.Avionics.TCAS~=true or typeof(ox.Position)~="Vector3" then return self.advisories end
 self.registry:ForEach(function(id,state) local a=add(state,id,ownId,ox.Position,tonumber(ox.Altitude) or 0); if a then self.advisories[#self.advisories+1]=a end end)
 table.sort(self.advisories,function(a,b) return a.RangeM<b.RangeM end)
 local c=self.advisories[1]; ox.TCAS.Advisories=self.advisories; ox.TCAS.ClosestIntruder=c and c.Intruder or nil; ox.TCAS.ClosestRangeM=c and c.RangeM or nil; ox.TCAS.HighestLevel=c and c.Level or "NONE"
 return self.advisories
end
return TCAS
