-- Regression tests for FlightEnvelope.lua
local Envelope=require(script.Parent.FlightEnvelope)
local function assertNear(a,b,tolerance,message)
 assert(math.abs(a-b)<=tolerance,message.." expected="..tostring(b).." actual="..tostring(a))
end
local function run()
 local base={
  Altitude=0,
  Airspeed=150,
  Mach=0.22,
  Mass=41412,
  WeightBalance={GrossMassKg=41412},
  Surface={Flap=0},
  Environment={TemperatureC=15},
  WeatherEffects={IcingLiftFactor=1},
  LoadFactor=1,
 }
 local clean=Envelope.Calculate(base)
 assert(clean.StallSpeedKt>100 and clean.StallSpeedKt<150,"clean stall speed must be finite and plausible")
 assert(clean.AcceleratedStallSpeedKt>=clean.StallSpeedKt,"1g accelerated stall speed must not be below 1g stall speed")
 assert(clean.Overspeed==false,"150 kt must not be an overspeed")
 local flap={
  Altitude=0,Airspeed=150,Mach=0.22,Mass=41412,
  WeightBalance={GrossMassKg=41412},Surface={Flap=1},
  Environment={TemperatureC=15},WeatherEffects={IcingLiftFactor=1},LoadFactor=1,
 }
 local flapped=Envelope.Calculate(flap)
 assert(flapped.StallSpeedKt<clean.StallSpeedKt,"flap should reduce modeled stall speed")
 local heavy={
  Altitude=0,Airspeed=150,Mach=0.22,Mass=62731,
  WeightBalance={GrossMassKg=62731},Surface={Flap=0},
  Environment={TemperatureC=15},WeatherEffects={IcingLiftFactor=1},LoadFactor=1,
 }
 local heavyResult=Envelope.Calculate(heavy)
 assert(heavyResult.StallSpeedKt>clean.StallSpeedKt,"higher mass should increase modeled stall speed")
 local highLoad=Envelope.Calculate({
  Altitude=0,Airspeed=200,Mach=0.30,Mass=41412,
  WeightBalance={GrossMassKg=41412},Surface={Flap=0},
  Environment={TemperatureC=15},WeatherEffects={IcingLiftFactor=1},LoadFactor=2,
 })
 assertNear(highLoad.AcceleratedStallSpeedKt,highLoad.StallSpeedKt*math.sqrt(2),0.01,"accelerated stall scaling")
 local over=Envelope.Calculate({
  Altitude=0,Airspeed=341,Mach=0.83,Mass=41412,
  WeightBalance={GrossMassKg=41412},Surface={Flap=0},
  Environment={TemperatureC=15},WeatherEffects={IcingLiftFactor=1},LoadFactor=1,
 })
 assert(over.Overspeed==true,"VMO/MMO exceedance must set overspeed")
 return true
end
return run()
