-- FlightSim weather coupling contract tests v0.1
local WeatherPhysics=require(script.Parent.WeatherPhysics)
local function wrap(s) return {Get=function() return s end} end
local function run()
 local s={Airspeed=120,Heading=90,Weather={WindU=-20,WindV=0,WindW=2,Turbulence=0.5,Icing=1,VisibilityKm=10}}; local w=WeatherPhysics.new(wrap(s)); w:Step(1/60); assert(math.abs(s.WeatherEffects.HeadwindKts+20)<1e-9); assert(math.abs(s.WeatherEffects.CrosswindKts)<1e-9); assert(s.WeatherEffects.IcingDragFactor>1 and s.WeatherEffects.IcingLiftFactor<1); assert(s.WeatherEffects.VisibilityFactor==0.2); assert(s.WeatherEffects.EffectiveAirspeed>0); return true end
return {Run=run}
