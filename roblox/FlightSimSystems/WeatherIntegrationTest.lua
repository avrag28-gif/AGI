-- FlightSim environment / weather-radar contract tests v0.1
local Environment=require(script.Parent.Environment)
local WeatherPhysics=require(script.Parent.WeatherPhysics)
local WeatherRadar=require(script.Parent.WeatherRadar)
local Avionics=require(script.Parent.Avionics)

local function check(c,m) if not c then error(m,2) end end
local function wrap(s) return {Get=function() return s end} end

local function run()
 local s={Altitude=10000,Airspeed=180,Heading=90,Electrical={Bus1=true,Bus2=false},Avionics={WeatherRadarEnabled=true,WeatherRadar=false}}
 local env=Environment.new(wrap(s)); local wp=WeatherPhysics.new(wrap(s)); local radar=WeatherRadar.new(wrap(s)); local av=Avionics.new(wrap(s))
 check(env:SetWind(90,40),"wind setup failed")
 check(env:SetAtmosphere(-5,1000),"atmosphere setup failed")
 check(env:SetVisibility(8),"visibility setup failed")
 check(env:SetHazards(0.8,0.7,0.4,true),"hazard setup failed")
 env:Step(1/60); av:Step(1/60); wp:Step(1/60)
 check(s.Weather~=nil,"weather state not generated")
 check(s.WeatherEffects~=nil,"weather effects not generated")
 check(math.abs(s.Weather.WindSpeed-40)<0.001,"wind speed did not propagate")
 check(s.WeatherEffects.CrosswindKts~=nil,"crosswind effect missing")
 check(s.WeatherEffects.IcingDragFactor>1,"icing drag effect missing")
 radar:Step()
 check(s.WeatherRadar.Powered==true,"weather radar did not power with avionics enabled")
 check(#s.WeatherRadar.Cells>0,"weather radar did not detect precipitation")
 s.Avionics.WeatherRadarEnabled=false
 av:Step(1/60); radar:Step()
 check(s.WeatherRadar.Powered==false,"weather radar remained powered after switch off")
 check(#s.WeatherRadar.Cells==0,"weather radar retained cells while powered off")
 return true
end
return {Run=run}
