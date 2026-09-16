-- FlightSim hydraulic subsystem test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local HydraulicTest={}
local function approx(a,b,t) return math.abs(a-b)<=t end
function HydraulicTest.ValidateDemand(state)
 local x=state:Get(); local d=x.HydraulicDemand or {}; local h=x.HydraulicState or {}
 assert((d.Total or 0)>=0 and (d.Total or 0)<=1,"total hydraulic demand out of range")
 assert((d.A or 0)>=0 and (d.A or 0)<=1,"hydraulic demand A out of range")
 assert((d.B or 0)>=0 and (d.B or 0)<=1,"hydraulic demand B out of range")
 assert((h.DemandBreakdown or {}).FlightControls~=nil,"flight-control demand missing")
 assert((h.DemandBreakdown or {}).LandingGear~=nil,"gear demand missing")
 assert((h.DemandBreakdown or {}).Brakes~=nil,"brake demand missing")
 return true
end
function HydraulicTest.ValidateFailureIsolation(state)
 local x=state:Get(); local h=x.Hydraulic or {}; local hs=x.HydraulicState or {}
 if hs.FailureA==true then assert(approx(h.A or 0,0,0.001),"failed hydraulic A must be depressurized") end
 if hs.FailureB==true then assert(approx(h.B or 0,0,0.001),"failed hydraulic B must be depressurized") end
 return true
end
function HydraulicTest.ValidatePressureBounds(state,config)
 local x=state:Get(); local h=x.Hydraulic or {}; local maxP=(config and config.HydraulicMax) or 3000
 assert((h.A or 0)>=0 and (h.A or 0)<=maxP,"hydraulic A pressure out of bounds")
 assert((h.B or 0)>=0 and (h.B or 0)<=maxP,"hydraulic B pressure out of bounds")
 return true
end
function HydraulicTest.ValidateConsumers(state)
 local x=state:Get(); local d=x.HydraulicDemand or {}; local h=x.HydraulicState or {}; local b=h.DemandBreakdown or {}
 local expected=math.max(tonumber(b.FlightControls) or 0,0)*0.50+math.max(tonumber(b.LandingGear) or 0,0)*0.30+math.max(tonumber(b.Brakes) or 0,0)*0.20
 expected=math.max(0,math.min(1,expected))
 assert(approx(tonumber(d.Total) or 0,expected,0.0001),"hydraulic demand aggregation mismatch")
 return true
end
return HydraulicTest
