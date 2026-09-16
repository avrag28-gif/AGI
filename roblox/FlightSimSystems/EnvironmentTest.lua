-- FlightSim environment contract tests v0.2
local Environment=require(script.Parent.Environment)
local function wrap(s) return {Get=function() return s end} end
local function run()
 local s={Altitude=0}; local e=Environment.new(wrap(s)); assert(e:SetWind(450,300)); assert(s.Environment.WindDirection==90 and s.Environment.WindSpeed==250); assert(e:SetAtmosphere(-120,2000)); assert(s.Environment.TemperatureC==-90 and s.Environment.PressureHpa==1100); assert(e:SetVisibility(-1)); assert(s.Environment.VisibilityKm==0.05); assert(e:SetHazards(2,-1,3,true)); assert(s.Environment.Precipitation==1 and s.Environment.Turbulence==0 and s.Environment.Icing==1 and s.Environment.Thunderstorm==true); e:Step(1/60); local w1=s.Weather.WindW; e:Step(1/60); local w2=s.Weather.WindW; assert(type(w1)=="number" and type(w2)=="number" and w1~=w2); local s2={Altitude=10000}; local e2=Environment.new(wrap(s2)); assert(e2:SetWind(90,50)); e2:Step(1/60); assert(math.abs(s2.Weather.WindU+50)<1e-9 and math.abs(s2.Weather.WindV)<1e-9); return true end
return {Run=run}
