-- FlightSim engine subsystem contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local EngineTest={}
local function approx(a,b,t) return math.abs((tonumber(a) or 0)-(tonumber(b) or 0))<=t end
local function assertRange(v,a,b,msg)
 v=tonumber(v) or 0
 assert(v>=a and v<=b,msg)
end
function EngineTest.ValidateBounds(state)
 local x=state:Get(); local engines=x.Engines or {}
 for i=1,2 do
  local e=engines[i] or {}
  assertRange(e.N1,0,100,"engine N1 out of bounds")
  assertRange(e.N2,0,100,"engine N2 out of bounds")
  assert((tonumber(e.EGT) or 0)>=0,"engine EGT must be non-negative")
  assert((tonumber(e.OilPressure) or 0)>=0,"engine oil pressure must be non-negative")
  assert((tonumber(e.FuelFlow) or 0)>=0,"engine fuel flow must be non-negative")
  assert((tonumber(e.Thrust) or 0)>=0,"engine thrust must be non-negative")
 end
 return true
end
function EngineTest.ValidateStoppedState(state)
 local x=state:Get(); local engines=x.Engines or {}
 for i=1,2 do
  local e=engines[i] or {}
  if e.Running~=true then
   assert(approx(e.Thrust,0,0.001),"stopped engine must have zero thrust")
   assert(approx(e.FuelFlow,0,0.001),"stopped engine must have zero fuel flow")
   assert(e.GeneratorAvailable~=true,"stopped engine must not provide generator availability")
  end
 end
 return true
end
function EngineTest.ValidateGeneratorDependency(state)
 local x=state:Get(); local engines=x.Engines or {}
 for i=1,2 do
  local e=engines[i] or {}
  if e.GeneratorAvailable==true then
   assert(e.Running==true,"engine generator cannot be available while engine is stopped")
   assert((tonumber(e.N2) or 0)>=50,"engine generator requires sufficient N2")
  end
 end
 return true
end
function EngineTest.ValidateFuelStarvation(state)
 local x=state:Get(); local engines=x.Engines or {}; local s=x.FuelSystem or {}; local available=s.EngineFuelAvailable or {}; local starved=s.EngineFuelStarved or {}
 for i=1,2 do
  local e=engines[i] or {}
  if starved[i]==true or available[i]==false then
   assert(e.Running~=true,"fuel-starved engine must not remain running")
   assert(e.FuelOn~=true or starved[i]~=true,"fuel-starved engine must not retain fuel-on state")
  end
 end
 return true
end
function EngineTest.ValidateAll(state)
 EngineTest.ValidateBounds(state)
 EngineTest.ValidateStoppedState(state)
 EngineTest.ValidateGeneratorDependency(state)
 EngineTest.ValidateFuelStarvation(state)
 return true
end
return EngineTest
