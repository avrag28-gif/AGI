-- Regression tests for fuel mass normalization.
local FuelMassBalance=require(script.Parent.Parent.FuelMassBalance)
local Profile=require(script.Parent.Parent.AircraftProfile)
local function assertEq(a,b,msg) assert(a==b,(msg or "assertEq").." expected="..tostring(b).." got="..tostring(a)) end
local function assertTrue(v,msg) assert(v,msg or "assertTrue") end
local empty=FuelMassBalance.Calculate({Fuel={Total=0}},Profile)
assertEq(empty.MassKg,0,"zero fuel mass")
local half=FuelMassBalance.Calculate({Fuel={Total=10000}},Profile)
assertEq(half.MassKg,10000,"fuel mass is 1:1 kg")
local capped=FuelMassBalance.Calculate({Fuel={Total=25000}},Profile)
assertEq(capped.MassKg,20897,"fuel capacity cap")
assertTrue(capped.OverCapacity,"over-capacity flag")
print("FuelMassBalanceTest PASS")
return true
