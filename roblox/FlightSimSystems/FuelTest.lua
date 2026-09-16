-- FlightSim fuel subsystem smoke-test helpers v0.1
local FuelTest={}
function FuelTest.Validate(state)
 local x=state:Get(); local f=x.Fuel or {}; local s=x.FuelSystem or {}
 assert((f.Total or -1)>=0,"fuel total must be non-negative")
 assert(math.abs((f.Total or 0)-((f.Left or 0)+(f.Center or 0)+(f.Right or 0)))<0.01,"fuel total mismatch")
 assert((s.TotalQuantity or -1)>=0,"fuel telemetry invalid")
 return true
end
return FuelTest
