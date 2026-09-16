-- FlightSim fuel subsystem contract-test helpers v0.2
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local FuelTest={}
local function approx(a,b,t) return math.abs((tonumber(a) or 0)-(tonumber(b) or 0))<=t end
local function assertRange(v,a,b,msg)
 v=tonumber(v) or 0
 assert(v>=a and v<=b,msg)
end
function FuelTest.Validate(state)
 local x=state:Get(); local f=x.Fuel or {}; local s=x.FuelSystem or {}
 assert((f.Total or -1)>=0,"fuel total must be non-negative")
 assert(math.abs((f.Total or 0)-((f.Left or 0)+(f.Center or 0)+(f.Right or 0)))<0.01,"fuel total mismatch")
 assert((s.TotalQuantity or -1)>=0,"fuel telemetry invalid")
 assertRange(s.FeedPressure,0,1,"feed pressure out of range")
 return true
end
function FuelTest.ValidateMassConservation(state)
 local x=state:Get(); local f=x.Fuel or {}; local s=x.FuelSystem or {}
 local total=(tonumber(f.Left) or 0)+(tonumber(f.Center) or 0)+(tonumber(f.Right) or 0)
 assert(approx(f.Total,total,0.01),"fuel mass conservation mismatch")
 assert(approx(s.TotalQuantity,total,0.01),"fuel system total mismatch")
 return true
end
function FuelTest.ValidatePumpIsolation(state)
 local x=state:Get(); local s=x.FuelSystem or {}; local failures=x.Failures and x.Failures.Fuel or {}
 if failures.LeftPump==true then assert(s.LeftFeed~=true,"failed left pump cannot report left feed") end
 if failures.CenterPump==true then assert(s.CenterFeed~=true,"failed center pump cannot report center feed") end
 if failures.RightPump==true then assert(s.RightFeed~=true,"failed right pump cannot report right feed") end
 return true
end
function FuelTest.ValidateEngineFeedFlags(state)
 local x=state:Get(); local s=x.FuelSystem or {}
 local available=s.EngineFuelAvailable or {}
 assert(type(available[1])=="boolean","engine 1 fuel availability must be boolean")
 assert(type(available[2])=="boolean","engine 2 fuel availability must be boolean")
 return true
end
function FuelTest.ValidateStarvationConsistency(state)
 local x=state:Get(); local s=x.FuelSystem or {}; local engines=x.Engines or {}
 local starved=s.EngineFuelStarved or {}
 for i=1,2 do
  if starved[i]==true then
   assert((s.EngineFuelDelivered and (s.EngineFuelDelivered[i] or 0) or 0)<=0.0001,"starved engine received fuel")
   if engines[i] and engines[i].Running==true then
    assert(engines[i].FuelOn~=true,"starved running engine still has fuel-on state")
   end
  end
 end
 return true
end
function FuelTest.ValidateAll(state)
 FuelTest.Validate(state)
 FuelTest.ValidateMassConservation(state)
 FuelTest.ValidatePumpIsolation(state)
 FuelTest.ValidateEngineFeedFlags(state)
 FuelTest.ValidateStarvationConsistency(state)
 return true
end
return FuelTest
