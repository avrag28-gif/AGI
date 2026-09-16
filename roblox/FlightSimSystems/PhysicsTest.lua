-- FlightSim physics integration contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local PhysicsTest={}
local function approx(a,b,t) return math.abs((tonumber(a) or 0)-(tonumber(b) or 0))<=t end
function PhysicsTest.ValidateBounds(state,config)
 local x=state:Get(); local maxSpeed=(config and config.MaxAirspeed) or 360; local maxAlt=(config and config.MaxAltitude) or 41000
 assert((x.Airspeed or 0)>=0 and (x.Airspeed or 0)<=maxSpeed,"airspeed out of bounds")
 assert((x.Altitude or 0)>=0 and (x.Altitude or 0)<=maxAlt,"altitude out of bounds")
 assert((x.Roll or 0)>=-75 and (x.Roll or 0)<=75,"roll out of bounds")
 assert((x.Pitch or 0)>=-35 and (x.Pitch or 0)<=35,"pitch out of bounds")
 return true
end
function PhysicsTest.ValidateEngineIntegration(state)
 local x=state:Get(); local e=x.Engines or {}; local i=x.EngineIntegration or {}
 local total=(tonumber(e[1] and e[1].Thrust) or 0)+(tonumber(e[2] and e[2].Thrust) or 0)
 assert(approx(i.TotalThrust,total,0.001),"integrated total thrust mismatch")
 assert((tonumber(i.LeftThrust) or 0)>=0 and (tonumber(i.RightThrust) or 0)>=0,"integrated thrust must be non-negative")
 assert((tonumber(i.ThrustAsymmetry) or 0)>=-1 and (tonumber(i.ThrustAsymmetry) or 0)<=1,"thrust asymmetry out of range")
 return true
end
function PhysicsTest.ValidateEngineOutYaw(state,config)
 local x=state:Get(); local i=x.EngineIntegration or {}; local left=tonumber(i.LeftThrust) or 0; local right=tonumber(i.RightThrust) or 0
 if left>0 and right>0 and math.abs(right-left)>0.01 then
  local gain=(config and config.EngineYawMomentGain) or 0.000055; local arm=(config and config.EngineLateralArm) or 6
  assert(approx(i.YawMoment,(right-left)*arm*gain,0.0001),"engine yaw moment mismatch")
 end
 return true
end
function PhysicsTest.ValidateReverseGroundOnly(state)
 local x=state:Get(); local l=x.Landing or {}
 if x.GroundContact~=true then assert(l.ReverseThrust~=true,"reverse thrust must not remain active airborne") end
 return true
end
function PhysicsTest.ValidateAll(state,config)
 PhysicsTest.ValidateBounds(state,config); PhysicsTest.ValidateEngineIntegration(state); PhysicsTest.ValidateEngineOutYaw(state,config); PhysicsTest.ValidateReverseGroundOnly(state)
 return true
end
return PhysicsTest
