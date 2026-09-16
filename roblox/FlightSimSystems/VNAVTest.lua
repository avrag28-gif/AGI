-- FlightSim VNAV contract-test helpers v0.4
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local VNAVTest={}
local function range(v,a,b,msg) if v==nil then return end; v=tonumber(v); assert(v and v==v,"VNAV value must be finite"); assert(v>=a and v<=b,msg) end
function VNAVTest.Validate(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 range(v.PathError,-60000,60000,"VNAV path error out of range"); range(v.VerticalSpeed,-2500,2500,"VNAV vertical speed out of range")
 range(v.TargetAltitude,0,60000,"VNAV target altitude out of range"); range(v.CommandVerticalSpeed,-2500,2500,"VNAV command vertical speed out of range")
 range(n.CommandVerticalSpeed,-2500,2500,"navigation vertical speed out of range"); range(v.DescentPathAngle,-6,6,"VNAV path angle out of range"); range(v.TargetSpeed,60,350,"VNAV target speed out of range")
 if v.ConstraintType~=nil then assert(v.ConstraintType=="AT" or v.ConstraintType=="ABOVE" or v.ConstraintType=="BELOW","invalid VNAV altitude constraint type") end
 if v.ConstraintAltitude~=nil then range(v.ConstraintAltitude,0,60000,"VNAV constraint altitude out of range") end
 if v.SpeedConstraintType~=nil then assert(v.SpeedConstraintType=="AT" or v.SpeedConstraintType=="ABOVE" or v.SpeedConstraintType=="BELOW" or v.SpeedConstraintType=="SELECTED","invalid VNAV speed constraint type") end
 return true
end
function VNAVTest.ValidateConsistency(state)
 local x=state:Get(); local v=x.VNAV or {}; local n=x.Navigation or {}
 if v.Mode=="VNAV" and v.TargetAltitude then
  assert(math.abs((tonumber(n.CommandAltitude) or 0)-v.TargetAltitude)<0.001,"VNAV altitude command mismatch")
  assert(math.abs((tonumber(n.CommandVerticalSpeed) or 0)-(tonumber(v.VerticalSpeed) or 0))<0.001,"VNAV VS command mismatch")
  assert(math.abs((tonumber(v.CommandVerticalSpeed) or 0)-(tonumber(v.VerticalSpeed) or 0))<0.001,"VNAV internal VS command mismatch")
  assert(v.ConstraintAltitude==nil or math.abs(v.ConstraintAltitude-v.TargetAltitude)<0.001,"VNAV constraint target mismatch")
 end
 if v.Mode=="VNAV" and v.TargetSpeed then assert(math.abs(v.TargetSpeed-(tonumber(v.TargetSpeed) or 0))<0.001,"VNAV speed target invalid") end
 return true
end
function VNAVTest.ValidateConstraintState(state)
 local x=state:Get(); local v=x.VNAV or {}; local alt=tonumber(x.Altitude) or 0; local speed=tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0
 if v.Mode=="VNAV" and v.ConstraintAltitude then
  if v.ConstraintType=="AT" and v.ConstraintSatisfied then assert(math.abs(alt-v.ConstraintAltitude)<=75,"AT constraint marked satisfied outside tolerance") end
  if v.ConstraintType=="ABOVE" and v.ConstraintSatisfied then assert(alt+100>=v.ConstraintAltitude,"ABOVE constraint marked satisfied too low") end
  if v.ConstraintType=="BELOW" and v.ConstraintSatisfied then assert(alt-100<=v.ConstraintAltitude,"BELOW constraint marked satisfied too high") end
 end
 if v.Mode=="VNAV" and v.TargetSpeed and v.SpeedConstraintSatisfied then
  if v.SpeedConstraintType=="AT" then assert(math.abs(speed-v.TargetSpeed)<=5,"AT speed constraint marked satisfied outside tolerance")
  elseif v.SpeedConstraintType=="ABOVE" then assert(speed+5>=v.TargetSpeed,"ABOVE speed constraint marked satisfied too slow")
  elseif v.SpeedConstraintType=="BELOW" then assert(speed-5<=v.TargetSpeed,"BELOW speed constraint marked satisfied too fast")
  end
 end
 return true
end
function VNAVTest.ValidateAll(state) VNAVTest.Validate(state); VNAVTest.ValidateConsistency(state); VNAVTest.ValidateConstraintState(state); return true end
return VNAVTest
