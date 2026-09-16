-- FlightSim weather-to-flight-model coupling v0.1
-- Converts environment state into bounded aerodynamic disturbances.
local WeatherPhysics={}; WeatherPhysics.__index=WeatherPhysics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function WeatherPhysics.new(state) return setmetatable({state=state},WeatherPhysics) end
function WeatherPhysics:Step(dt)
 local x=self.state:Get(); local w=x.Weather or {}; local speed=math.max(tonumber(x.Airspeed) or 0,0); local hdg=math.rad(tonumber(x.Heading) or 0); local windU=tonumber(w.WindU) or 0; local windV=tonumber(w.WindV) or 0; local forwardX,forwardZ=math.sin(hdg),math.cos(hdg)
 local headwind=windU*forwardX+windV*forwardZ; local crosswind=windU*forwardZ-windV*forwardX
 local gust=tonumber(w.WindW) or 0; local turbulence=clamp(tonumber(w.Turbulence) or 0,0,1); local icing=clamp(tonumber(w.Icing) or 0,0,1)
 x.WeatherEffects={HeadwindKts=headwind,CrosswindKts=crosswind,GustKts=gust,EffectiveAirspeed=clamp(speed+headwind+gust,0,500),TurbulencePitch=gust*0.015,TurbulenceRoll=clamp(crosswind*0.01,-1.5,1.5),IcingDragFactor=1+0.12*icing,IcingLiftFactor=1-0.08*icing,VisibilityFactor=clamp((tonumber(w.VisibilityKm) or 50)/50,0,1)}
 if x.Environment then x.Environment.IcingEffect=icing end
end
return WeatherPhysics
