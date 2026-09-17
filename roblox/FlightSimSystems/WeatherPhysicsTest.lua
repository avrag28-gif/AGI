-- FlightSim weather coupling contract tests v0.3
local WeatherPhysics=require(script.Parent.WeatherPhysics)
local function wrap(s) return {Get=function() return s end} end
local function near(a,b,t) return math.abs(a-b)<=t end
local function run()
 local s={Airspeed=120,Heading=90,Weather={WindU=-20,WindV=0,WindW=2,Turbulence=0.5,Icing=1,VisibilityKm=10}}; local w=WeatherPhysics.new(wrap(s)); w:Step(1/60)
 assert(near(s.WeatherEffects.HeadwindKts,20,1e-9),"headwind projection is incorrect")
 assert(near(s.WeatherEffects.CrosswindKts,0,1e-9),"crosswind projection is incorrect")
 assert(near(s.WeatherEffects.EffectiveAirspeed,120+2*(2.5/60),1e-9),"headwind must not be double-counted in aerodynamic airspeed")
 assert(near(s.WeatherEffects.RelativeWindSpeedKts,s.WeatherEffects.EffectiveAirspeed,1e-9),"relative-wind speed must mirror effective aerodynamic airspeed")
 assert(near(s.WeatherEffects.AirspeedDisturbanceKts,2*(2.5/60),1e-9),"gust smoothing is incorrect")
 assert(near(s.WeatherEffects.WindUKts,-20,1e-9) and near(s.WeatherEffects.WindVKts,0,1e-9),"world wind vector was not preserved")
 assert(s.WeatherEffects.IcingDragFactor>1 and s.WeatherEffects.IcingDragFactor<=1.12,"icing drag factor is out of bounds")
 assert(s.WeatherEffects.IcingLiftFactor<1 and s.WeatherEffects.IcingLiftFactor>=0.88,"icing lift factor is out of bounds")
 assert(near(s.WeatherEffects.VisibilityFactor,0.2,1e-9),"visibility factor is incorrect")
 assert(near(s.WeatherEffects.GustKts,2*(2.5/60),1e-9),"gust state is incorrect")

 local calm={Airspeed=120,Heading=90,Weather={WindU=-20,WindV=0,WindW=0,Turbulence=0,Icing=0,VisibilityKm=50}}; WeatherPhysics.new(wrap(calm)):Step(1/60)
 assert(near(calm.WeatherEffects.EffectiveAirspeed,120,1e-9),"pure headwind must leave true aerodynamic airspeed unchanged")
 assert(near(calm.WeatherEffects.IcingDragFactor,1,1e-9) and near(calm.WeatherEffects.IcingLiftFactor,1,1e-9),"clear-air icing factors must be neutral")
 return true
end
return {Run=run}
