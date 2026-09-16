-- FlightSim flight-control subsystem contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local FlightControlsTest={}
local function range(v,a,b,msg)
 v=tonumber(v) or 0
 assert(v>=a and v<=b,msg)
end
function FlightControlsTest.ValidateSurfaceBounds(state)
 local x=state:Get(); local s=x.Surface or {}
 range(s.Aileron,-1,1,"aileron surface out of range")
 range(s.Elevator,-1,1,"elevator surface out of range")
 range(s.Rudder,-1,1,"rudder surface out of range")
 range(s.Flap,0,1,"flap surface out of range")
 return true
end
function FlightControlsTest.ValidateHydraulicDemand(state)
 local x=state:Get(); local d=x.HydraulicDemand or {}
 range(d.FlightControls,0,1,"flight-control hydraulic demand out of range")
 range(d.A,0,1,"hydraulic demand A out of range")
 range(d.B,0,1,"hydraulic demand B out of range")
 return true
end
function FlightControlsTest.ValidateAuthority(state)
 local x=state:Get(); local f=x.ControlFeel or {}
 range(f.HydraulicAuthority,0,1,"hydraulic authority out of range")
 range(f.AileronAuthority,0,1.15,"aileron authority out of range")
 range(f.ElevatorAuthority,0,1.15,"elevator authority out of range")
 range(f.RudderAuthority,0,1.15,"rudder authority out of range")
 return true
end
function FlightControlsTest.ValidateTrim(state)
 local x=state:Get()
 assert((tonumber(x.TrimPitch) or 0)>=-10 and (tonumber(x.TrimPitch) or 0)<=10,"trim pitch out of range")
 local t=x.TrimState or {}
 range(t.Command,-1,1,"trim command out of range")
 assert(math.abs((tonumber(t.Pitch) or 0)-(tonumber(x.TrimPitch) or 0))<0.0001,"trim telemetry mismatch")
 return true
end
function FlightControlsTest.ValidateAll(state)
 FlightControlsTest.ValidateSurfaceBounds(state)
 FlightControlsTest.ValidateHydraulicDemand(state)
 FlightControlsTest.ValidateAuthority(state)
 FlightControlsTest.ValidateTrim(state)
 return true
end
return FlightControlsTest
