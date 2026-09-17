-- FlightSim 737-800 weight and balance foundation v1.0
-- Uses aircraft profile limits and current fuel/payload state.
-- CG is a baseline placeholder until loading stations and tank arms are modeled.
local Profile=require(script.Parent.AircraftProfile)
local WeightBalance={}
local function finite(v,d)
 v=tonumber(v)
 return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

function WeightBalance.Calculate(state)
 local profile=Profile.Weights
 local fuel=state.Fuel or {}
 local wb=state.WeightBalance or {}
 local empty=math.max(0,finite(profile.OperatingEmptyMassKg,0))
 local fuelMass=math.max(0,finite(fuel.Total,0))
 local payload=math.max(0,finite(state.PayloadMassKg,finite(wb.PayloadMassKg,0)))
 local zeroFuel=empty+payload
 local gross=zeroFuel+fuelMass
 local mtow=math.max(0,finite(profile.MaxTakeoffMassKg,math.huge))
 local mlw=math.max(0,finite(profile.MaxLandingMassKg,math.huge))
 local mzfw=math.max(0,finite(profile.MaxZeroFuelMassKg,math.huge))
 local mtw=math.max(0,finite(profile.MaxTaxiMassKg,math.huge))
 local cg=clamp(finite(state.CGPercentMAC,finite(wb.CenterOfGravityPercentMAC,profile.ReferenceCGPercentMAC or 25)),15,35)
 local result={
  OperatingEmptyMassKg=empty,
  PayloadMassKg=payload,
  FuelMassKg=fuelMass,
  ZeroFuelMassKg=zeroFuel,
  GrossMassKg=gross,
  CenterOfGravityPercentMAC=cg,
  MaxTakeoffMassKg=mtow,
  MaxLandingMassKg=mlw,
  MaxZeroFuelMassKg=mzfw,
  MaxTaxiMassKg=mtw,
  Overweight=gross>mtow,
  TakeoffWeightLimited=gross>mtow,
  LandingWeightLimited=gross>mlw,
  ZeroFuelWeightLimited=zeroFuel>mzfw,
  TaxiWeightLimited=gross>mtw,
  TakeoffMarginKg=mtow-gross,
  LandingMarginKg=mlw-gross,
  ZeroFuelMarginKg=mzfw-zeroFuel,
  TaxiMarginKg=mtw-gross,
 }
 return result
end

function WeightBalance.Step(state)
 local result=WeightBalance.Calculate(state)
 state.WeightBalance=result
 state.Mass=result.GrossMassKg
 state.Weight=result.GrossMassKg*9.80665
 state.CGPercentMAC=result.CenterOfGravityPercentMAC
 state.WeightLimitExceeded=result.Overweight
 state.WeightMarginKg=result.TakeoffMarginKg
 return result
end

return WeightBalance
