-- FlightSim failure subsystem deterministic validation helpers v0.1
-- These helpers validate state contracts only; they do not run Roblox physics.
local FailureTest={}

local function assertBool(value,message)
 assert(type(value)=="boolean",message)
end

local function assertRange(value,minValue,maxValue,message)
 value=tonumber(value)
 assert(value~=nil and value>=minValue and value<=maxValue,message)
end

function FailureTest.ValidateEngineFailureSeparation(state)
 local x=state:Get(); local failures=x.Failures or {}; local engines=failures.Engines or {}
 for i=1,2 do
  local f=engines[i] or {}
  assertBool(f.Active==true or f.Active==false,"engine failure Active must be boolean")
  assertBool(f.Fire==true or f.Fire==false,"engine failure Fire must be boolean")
  if f.Active==true then
   local e=x.Engines and x.Engines[i] or {}
   assert(e.Running~=true,"failed engine must not remain running")
   assert((e.Thrust or 0)==0,"failed engine thrust must be zero")
  end
 end
 return true
end

function FailureTest.ValidateFireSeparation(state)
 local x=state:Get(); local failures=x.Failures or {}; local engines=failures.Engines or {}
 local fp=failures.FireProtection or {}; local fpEngines=fp.Engines or {}
 for i=1,2 do
  local generic=engines[i] or {}; local fire=fpEngines[i] or {}
  assertBool(generic.Fire==true or generic.Fire==false,"engine fire flag must be boolean")
  assertBool(fire.Fire==true or fire.Fire==false,"fire-protection engine fire flag must be boolean")
  assert(generic.Fire==fire.Fire,"engine fire state must be synchronized")
 end
 return true
end

function FailureTest.ValidateHydraulicIsolation(state)
 local x=state:Get(); local failures=x.Failures or {}; local hf=failures.Hydraulic or {}; local h=x.Hydraulic or {}
 assertBool(hf.A==true or hf.A==false,"hydraulic A failure must be boolean")
 assertBool(hf.B==true or hf.B==false,"hydraulic B failure must be boolean")
 if hf.A==true then assert((h.A or 0)==0,"failed hydraulic A must be depressurized") end
 if hf.B==true then assert((h.B or 0)==0,"failed hydraulic B must be depressurized") end
 return true
end

function FailureTest.ValidateElectricalIsolation(state)
 local x=state:Get(); local failures=x.Failures or {}; local ef=failures.Electrical or {}; local e=x.Electrical or {}
 assertBool(ef.Bus1==true or ef.Bus1==false,"electrical Bus1 failure must be boolean")
 assertBool(ef.Bus2==true or ef.Bus2==false,"electrical Bus2 failure must be boolean")
 if ef.Bus1==true then assert(e.Bus1~=true,"failed Bus1 must be unavailable") end
 if ef.Bus2==true then assert(e.Bus2~=true,"failed Bus2 must be unavailable") end
 return true
end

function FailureTest.ValidateFlightControlAuthority(state)
 local x=state:Get(); local failures=x.Failures or {}; local cf=failures.FlightControls or {}; local effects=x.FailureEffects or {}
 local pairs={{"Aileron",effects.AileronAuthority},{"Elevator",effects.ElevatorAuthority},{"Rudder",effects.RudderAuthority}}
 for _,item in ipairs(pairs) do
  local surface=item[1]; local authority=item[2]
  assertRange(authority,0,1,surface.." authority out of range")
  if cf[surface]==true then assert(authority==0,surface.." authority must be zero after failure") end
 end
 return true
end

function FailureTest.ValidateAll(state)
 FailureTest.ValidateEngineFailureSeparation(state)
 FailureTest.ValidateFireSeparation(state)
 FailureTest.ValidateHydraulicIsolation(state)
 FailureTest.ValidateElectricalIsolation(state)
 FailureTest.ValidateFlightControlAuthority(state)
 return true
end

return FailureTest
