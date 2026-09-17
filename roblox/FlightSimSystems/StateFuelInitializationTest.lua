-- State cold-dark initialization regression test v0.1
local State=require(script.Parent.State)
local AircraftProfile=require(script.Parent.AircraftProfile)
local Test={}
local function check(ok,msg) if not ok then error(msg,2) end end
function Test.Run()
 local state=State.new()
 local maxFuel=AircraftProfile.Fuel.MaxUsableMassKg
 check(state.Phase=="ColdAndDark","new state must start cold and dark")
 check(state.Fuel.Total==0,"cold-dark usable fuel must start at zero")
 check(state.FuelSystem.TotalQuantity==0,"cold-dark fuel-system quantity must start at zero")
 check(state.Fuel.Total<=maxFuel,"cold-dark fuel must not exceed aircraft usable-fuel limit")
 check(state.WeightBalance.FuelMassKg==0,"cold-dark weight balance must start with zero fuel mass")
 return true
end
return Test
