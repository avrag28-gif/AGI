-- FlightSim VNAV contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local VNAVTest={}
local function range(v,a,b,msg) v=tonumber(v) or 0; assert(v>=a and v<=b,msg) end
function VNAVTest.Validate(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 range(v.PathError,-60000,60000,"VNAV path error out of range")
 range(v.VerticalSpeed,-2500,2500,"VNAV vertical speed out of range")
 range(v.TargetAltitude,0,60000,"VNAV target altitude out of range")
 range(n.CommandVerticalSpeed,-2500,2500,"navigation vertical speed out of range")
 return true
end
function VNAVTest.ValidateConsistency(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 if v.Mode=="VNAV" and v.TargetAltitude then
  assert(math.abs((tonumber(n.CommandAltitude) or 0)-v.TargetAltitude)<0.001,"VNAV altitude command mismatch")
  assert(math.abs((tonumber(n.CommandVerticalSpeed) or 0)-(tonumber(v.VerticalSpeed) or 0))<0.001,"VNAV VS command mismatch")
 end
 return true
end
function VNAVTest.ValidateAll(state) VNAVTest.Validate(state); VNAVTest.ValidateConsistency(state); return true end
return VNAVTest
