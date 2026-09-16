-- FlightSim TCAS-style traffic advisory foundation v0.1
-- Game simulation advisory logic; not certified TCAS II/ACAS implementation.
local TCAS={}; TCAS.__index=TCAS
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function TCAS.new(registry) return setmetatable({registry=registry,advisories={}},TCAS) end
function TCAS:Step(ownId)
 self.advisories={}; local own=self.registry:Get(ownId); if not own then return self.advisories end
 local ox=own:Get(); local ownPos=ox.Position; local ownAlt=tonumber(ox.Altitude) or 0
 if typeof(ownPos)~="Vector3" then return self.advisories end
 self.registry:ForEach(function(id,state)
  if id==ownId then return end
  local x=state:Get(); local p=x.Position; if typeof(p)~="Vector3" then return end
  local d=(p-ownPos).Magnitude; local v=math.abs((tonumber(x.Altitude) or 0)-ownAlt)
  if d<=5000 and v<=1000 then
   local level=d<=1500 and "RA" or "TA"; self.advisories[#self.advisories+1]={Intruder=id,RangeM=d,VerticalSeparationFt=v,Level=level}
  end
 end)
 table.sort(self.advisories,function(a,b) return a.RangeM<b.RangeM end); return self.advisories
end
function TCAS:GetAdvisories() return self.advisories end
return TCAS
