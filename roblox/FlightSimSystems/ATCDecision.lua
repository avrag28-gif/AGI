-- FlightSim ATC conflict decision layer v0.2
-- Converts separation conflicts into deterministic game-simulation instructions.
local ATCDecision={}; ATCDecision.__index=ATCDecision
local function norm(v) return string.upper(tostring(v or "")) end
local function finite(v,d) v=tonumber(v); if not v or v~=v or v==math.huge or v==-math.huge then return d end; return v end
function ATCDecision.new(separation) return setmetatable({separation=separation,decisions={}},ATCDecision) end
local function shouldReplace(old,new)
 if not old then return true end
 if old.Instruction=="HOLD_POSITION" and new.Instruction~="HOLD_POSITION" then return false end
 if old.Instruction~="HOLD_POSITION" and new.Instruction=="HOLD_POSITION" then return true end
 return finite(new.DistanceM,math.huge)<finite(old.DistanceM,math.huge)
end
function ATCDecision:Step()
 self.decisions={}
 for _,c in ipairs(self.separation:GetConflicts()) do
  local instruction=c.GroundConflict and "HOLD_POSITION" or "TRAFFIC_ALERT"
  local a,b=c.AircraftA,c.AircraftB
  local da={Instruction=instruction,ConflictWith=b,DistanceM=finite(c.DistanceM,math.huge),VerticalSeparationFt=finite(c.VerticalSeparationFt,math.huge),GroundConflict=c.GroundConflict==true}
  local db={Instruction=instruction,ConflictWith=a,DistanceM=da.DistanceM,VerticalSeparationFt=da.VerticalSeparationFt,GroundConflict=da.GroundConflict}
  if shouldReplace(self.decisions[a],da) then self.decisions[a]=da end
  if shouldReplace(self.decisions[b],db) then self.decisions[b]=db end
 end
 return self.decisions
end
function ATCDecision:Get(aircraftId) return self.decisions[aircraftId] end
function ATCDecision:ShouldHold(aircraftId) local d=self.decisions[aircraftId]; return d~=nil and norm(d.Instruction)=="HOLD_POSITION" end
return ATCDecision
