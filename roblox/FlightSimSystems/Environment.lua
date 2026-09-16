-- FlightSim environment / weather model v0.2
-- Deterministic simulation state; weather values are game-simulation approximations.
local Environment={}; Environment.__index=Environment
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function ensure(x)
 x.Environment=x.Environment or {WindDirection=0,WindSpeed=0,TemperatureC=15,PressureHpa=1013.25,VisibilityKm=50,Precipitation=0,Turbulence=0,Icing=0,CloudBaseFt=12000,CeilingFt=25000,Thunderstorm=false,OutsideAirTemperatureC=15,WindU=0,WindV=0,WindW=0,TurbulencePhase=0}
 local e=x.Environment; if e.TurbulencePhase==nil then e.TurbulencePhase=0 end; return e
end
function Environment.new(state) return setmetatable({state=state},Environment) end
function Environment:SetWind(direction,speed)
 direction=tonumber(direction); speed=tonumber(speed); if not finite(direction) or not finite(speed) then return false,"invalid_wind" end; local e=ensure(self.state:Get()); e.WindDirection=(direction%360+360)%360; e.WindSpeed=clamp(speed,0,250); return true
end
function Environment:SetAtmosphere(tempC,pressureHpa)
 tempC=tonumber(tempC); pressureHpa=tonumber(pressureHpa); if not finite(tempC) or not finite(pressureHpa) then return false,"invalid_atmosphere" end; local e=ensure(self.state:Get()); e.TemperatureC=clamp(tempC,-90,60); e.PressureHpa=clamp(pressureHpa,150,1100); return true
end
function Environment:SetVisibility(km)
 km=tonumber(km); if not finite(km) then return false,"invalid_visibility" end; ensure(self.state:Get()).VisibilityKm=clamp(km,0.05,100); return true
end
function Environment:SetHazards(precipitation,turbulence,icing,thunderstorm)
 local p,t,i=tonumber(precipitation),tonumber(turbulence),tonumber(icing); if not finite(p) or not finite(t) or not finite(i) then return false,"invalid_weather_hazard" end; local e=ensure(self.state:Get()); e.Precipitation=clamp(p,0,1); e.Turbulence=clamp(t,0,1); e.Icing=clamp(i,0,1); e.Thunderstorm=thunderstorm==true; return true
end
function Environment:Step(dt)
 local x=self.state:Get(); local e=ensure(x); local altitude=math.max(0,tonumber(x.Altitude) or 0); local isaTemp=15-0.0065*altitude; e.OutsideAirTemperatureC=clamp(e.TemperatureC+(isaTemp-e.TemperatureC)*clamp(altitude/20000,0,1),-90,60)
 local rad=math.rad(e.WindDirection); e.WindU=-math.sin(rad)*e.WindSpeed; e.WindV=-math.cos(rad)*e.WindSpeed; e.TurbulencePhase=(e.TurbulencePhase+math.max(0,dt)*1.7)%(math.pi*2); e.WindW=e.Turbulence*math.sin(e.TurbulencePhase)*2
 x.Weather={WindDirection=e.WindDirection,WindSpeed=e.WindSpeed,TemperatureC=e.OutsideAirTemperatureC,PressureHpa=e.PressureHpa,VisibilityKm=e.VisibilityKm,Precipitation=e.Precipitation,Turbulence=e.Turbulence,Icing=e.Icing,Thunderstorm=e.Thunderstorm,WindU=e.WindU,WindV=e.WindV,WindW=e.WindW}
end
return Environment
