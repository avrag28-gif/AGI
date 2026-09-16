-- FlightSim VNAV contract-test helpers v0.2
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local VNAVTest={}
local function range(v,a,b,msg) if v==nil then return end; v=tonumber(v); assert(v and v==v,"VNAV value must be finite"); assert(v>=a and v<=b,msg) end
function VNAVTest.Validate(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 range(v.PathError,-60000,60000,"VNAV path error out of range"); range(v.VerticalSpeed,-2500,2500,"VNAV vertical speed out of range")
 range(v.TargetAltitude,0,60000,"VNAV target altitude out of range"); range(v.CommandVerticalSpeed,-2500,2500,"VNAV command vertical speed out of range")
 range(n.CommandVerticalSpeed,-2500,2500,"navigation vertical speed out of range"); range(v.DescentPathAngle,-6,6,"VNAV path angle out of range")
 return true
end
function VNAVTest.ValidateConsistency(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 if v.Mode=="VNAV" and v.TargetAltitude then
  assert(math.abs((tonumber(n.CommandAltitude) or 0)-v.TargetAltitude)<0.001,"VNAV altitude command mismatch")
  assert(math.abs((tonumber(n.CommandVerticalSpeed) or 0)-(tonumber(v.VerticalSpeed) or 0))<0.001,"VNAV VS command mismatch")
  assert(math.abs((tonumber(v.CommandVerticalSpeed) or 0)-(tonumber(v.VerticalSpeed) or 0))<0.001,"VNAV internal VS command mismatch")
 end
 return true
end
function VNAVTest.ValidateAll(state) VNAVTest.Validate(state); VNAVTest.ValidateConsistency(state); return true end
return VNAVTest
