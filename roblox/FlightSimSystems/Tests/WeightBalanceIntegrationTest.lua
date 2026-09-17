-- WeightBalance integration regression test v1.0
local State=require(script.Parent.Parent.State)
local WeightBalance=require(script.Parent.Parent.WeightBalance)
local function approx(a,b,t) return math.abs(a-b)<=t end
local s=State.new()
local r=WeightBalance.Step(s)
assert(approx(r.OperatingEmptyMassKg,41413,0.01),"OEW contract mismatch")
assert(approx(r.FuelMassKg,30000,0.01),"Fuel mass must come from Fuel.Total")
assert(approx(r.GrossMassKg,71413,0.01),"Gross mass must equal OEW + fuel + payload")
assert(r.Overweight==false,"Initial gross mass should be below MTOW")
assert(approx(r.MaxTakeoffMassKg,79016,0.01),"MTOW contract mismatch")
s.PayloadMassKg=7000
r=WeightBalance.Step(s)
assert(approx(r.GrossMassKg,78413,0.01),"Payload must add to gross mass")
assert(r.Overweight==false,"78413 kg must remain below 79016 kg MTOW")
s.PayloadMassKg=9000
r=WeightBalance.Step(s)
assert(r.Overweight==true,"Gross mass above MTOW must be flagged")
assert(r.TakeoffWeightLimited==true,"Takeoff weight limit must be flagged")
s.Fuel.Total=-100
r=WeightBalance.Step(s)
assert(r.FuelMassKg==0,"Negative fuel must be clamped")
print("WeightBalanceIntegrationTest PASS")
return true
