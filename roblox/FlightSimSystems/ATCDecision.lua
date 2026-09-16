-- FlightSim ATC conflict decision layer v0.1
-- Converts separation conflicts into conservative game-simulation instructions.
local ATCDecision={}; ATCDecision.__index=ATCDecision
local function norm(v) return string.upper(tostring(v or "")) end
function ATCDecision.new(separation) return setmetatable({separation=separation,decisions={}},ATCDecision) end
function ATCDecision:Step()
 self.decisions={}
 for _,c in ipairs(self.separation:GetConflicts()) do
  local a,b=c.AircraftA,c.AircraftB
  local instruction=c.GroundConflict and "HOLD_POSITION" or "TRAFFIC_ALERT"
  self.decisions[a]={Instruction=instruction,ConflictWith=b,DistanceM=c.DistanceM,VerticalSeparationFt=c.VerticalSeparationFt}
  self.decisions[b]={Instruction=instruction,ConflictWith=a,DistanceM=c.DistanceM,VerticalSeparationFt=c.VerticalSeparationFt}
 end
 return self.decisions
end
function ATCDecision:Get(aircraftId) return self.decisions[aircraftId] end
function ATCDecision:ShouldHold(aircraftId)
 local d=self.decisions[aircraftId]; return d~=nil and norm(d.Instruction)=="HOLD_POSITION" end
return ATCDecision
