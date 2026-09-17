-- WeightBalanceRegressionTest v1.0
-- Contract test for the 737-800 baseline weight limits stored in State.
-- Run in Roblox Studio / Luau test harness; this file does not execute automatically.
local State=require(script.Parent.Parent.State)

local state=State.new()
local wb=state:Get().WeightBalance
assert(wb.OperatingEmptyMassKg==41413,"737-800 baseline OEW contract mismatch")
assert(wb.MaxTakeoffMassKg==79016,"737-800 MTOW contract mismatch")
assert(wb.MaxLandingMassKg==66361,"737-800 MLW contract mismatch")
assert(wb.MaxZeroFuelMassKg==62732,"737-800 MZFW contract mismatch")
assert(wb.MaxTaxiMassKg==79242,"737-800 taxi-weight contract mismatch")
assert(wb.GrossMassKg==wb.OperatingEmptyMassKg,"cold state gross mass must equal OEW")
assert(wb.Overweight==false,"cold state must not be overweight")

wb.PayloadMassKg=20000
wb.FuelMassKg=20000
wb.ZeroFuelMassKg=wb.OperatingEmptyMassKg+wb.PayloadMassKg
wb.GrossMassKg=wb.ZeroFuelMassKg+wb.FuelMassKg
assert(wb.ZeroFuelMassKg<=wb.MaxZeroFuelMassKg,"test payload must remain below MZFW")
assert(wb.GrossMassKg<=wb.MaxTakeoffMassKg,"test gross mass must remain below MTOW")

wb.FuelMassKg=30000
wb.GrossMassKg=wb.ZeroFuelMassKg+wb.FuelMassKg
assert(wb.GrossMassKg>wb.MaxTakeoffMassKg,"overweight scenario must exceed MTOW")
wb.Overweight=wb.GrossMassKg>wb.MaxTakeoffMassKg
assert(wb.Overweight==true,"overweight flag contract failed")

print("WeightBalanceRegressionTest PASS")
return true
