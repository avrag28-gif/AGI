-- FlightSim traffic separation / conflict detector v0.1
-- Game-simulation safety layer. Distances are configurable simulation thresholds,
-- not certified real-world separation minima.
local ATCSeparation={}; ATCSeparation.__index=ATCSeparation
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function distance(a,b) local pa=a.Position; local pb=b.Position; if typeof(pa)~="Vector3" or typeof(pb)~="Vector3" then return nil end return (pa-pb).Magnitude end
function ATCSeparation.new(registry,config) return setmetatable({registry=registry,config=config or {},conflicts={},thresholds={ground=150,air=2500,vertical=500}},ATCSeparation) end
function ATCSeparation:SetThresholds(ground,air,vertical)
 if not finite(ground) or ground<1 or not finite(air) or air<1 or not finite(vertical) or vertical<1 then return false,"invalid_threshold" end
 self.thresholds.ground=ground; self.thresholds.air=air; self.thresholds.vertical=vertical; return true
end
function ATCSeparation:Step()
 self.conflicts={}; local aircraft={}; self.registry:ForEach(function(id,state,owner) local x=state:Get(); aircraft[#aircraft+1]={Id=id,State=x,Owner=owner} end)
 for i=1,#aircraft-1 do for j=i+1,#aircraft do local a,b=aircraft[i],aircraft[j]; local d=distance(a.State,b.State); if d then local vertical=math.abs((tonumber(a.State.Altitude) or 0)-(tonumber(b.State.Altitude) or 0)); local onGround=a.State.GroundContact==true and b.State.GroundContact==true; local limit=onGround and self.thresholds.ground or self.thresholds.air; if d<=limit and (onGround or vertical<=self.thresholds.vertical) then self.conflicts[#self.conflicts+1]={AircraftA=a.Id,AircraftB=b.Id,DistanceM=d,VerticalSeparationFt=vertical,GroundConflict=onGround} end end end end
 return self.conflicts
end
function ATCSeparation:GetConflicts() return self.conflicts end
function ATCSeparation:IsConflicted(aircraftId)
 for _,c in ipairs(self.conflicts) do if c.AircraftA==aircraftId or c.AircraftB==aircraftId then return true,c end end
 return false,nil
end
return ATCSeparation
