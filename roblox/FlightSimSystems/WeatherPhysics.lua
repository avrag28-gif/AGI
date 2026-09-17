-- FlightSim weather-to-flight-model coupling v0.5
-- Wind is ground-relative. Headwind/crosswind therefore affect ground velocity
-- and directional stability, but must not be added to aerodynamic airspeed.
-- Gust is retained as a bounded scalar air-relative disturbance because this
-- simulation does not yet model a full 3-axis relative-wind vector.
local WeatherPhysics={}; WeatherPhysics.__index=WeatherPhysics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v,d) v=tonumber(v); if not v or v~=v or v==math.huge or v==-math.huge then return d end return v end
function WeatherPhysics.new(state) return setmetatable({state=state},WeatherPhysics) end
function WeatherPhysics:Step(dt)
 local x=self.state:Get(); local w=x.Weather or {}; local speed=math.max(finite(x.Airspeed,0),0); local hdg=math.rad(finite(x.Heading,0)); local windU=finite(w.WindU,0); local windV=finite(w.WindV,0)
 local forwardX,forwardZ=math.sin(hdg),math.cos(hdg); local windAlong=windU*forwardX+windV*forwardZ; local headwind=-windAlong; local crosswind=windU*forwardZ-windV*forwardX
 local gust=clamp(finite(w.WindW,0),-20,20); local turbulence=clamp(finite(w.Turbulence,0),0,1); local icing=clamp(finite(w.Icing,0),0,1); local visibility=math.max(finite(w.VisibilityKm,50),0.05)
 local previous=x.WeatherEffects or {}; local oldGust=finite(previous.GustKts,0); local gustState=oldGust+(gust-oldGust)*clamp(math.max(dt,0)*2.5,0,1)
 local turbulenceScale=0.35+0.65*turbulence
 -- Headwind/crosswind are already added to world velocity by Physics.
 -- Adding headwind here would double-count wind in aerodynamic speed.
 local relativeWindSpeed=clamp(speed+gustState,0,500)
 local icingDragFactor=1+0.12*icing
 local icingLiftFactor=1-0.12*icing
 x.WeatherEffects={HeadwindKts=headwind,CrosswindKts=crosswind,GustKts=gustState,EffectiveAirspeed=relativeWindSpeed,RelativeWindSpeedKts=relativeWindSpeed,AirspeedDisturbanceKts=gustState,WindUKts=windU,WindVKts=windV,TurbulencePitch=gustState*0.015*turbulenceScale,TurbulenceRoll=clamp(crosswind*0.01*turbulenceScale,-1.5,1.5),RawIcing=icing,IcingResidual=icing,IcingDragFactor=icingDragFactor,IcingLiftFactor=icingLiftFactor,VisibilityFactor=clamp(visibility/50,0,1)}
 if x.Environment then x.Environment.IcingEffect=icing end
end
return WeatherPhysics
