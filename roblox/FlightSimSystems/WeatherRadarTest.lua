-- FlightSim weather radar deterministic contract tests v0.1
local WeatherRadar=require(script.Parent.WeatherRadar)
local function check(ok,msg) assert(ok,msg) end
local function newState(power)
 return {Get=function() return {Avionics={WeatherRadar=power},Weather={VisibilityKm=20,Precipitation=0,Turbulence=0,Thunderstorm=false,WindDirection=90}} end}
end
local function run()
 local r=WeatherRadar.new(newState(false)):Step(); check(not r.Powered,"radar should be unpowered"); check(#r.Cells==0,"unpowered radar must have no cells")
 local state={data={Avionics={WeatherRadar=true},Weather={VisibilityKm=20,Precipitation=0,Turbulence=0,Thunderstorm=false,WindDirection=90}},Get=function(self)return self.data end}
 r=WeatherRadar.new(state):Step(); check(r.Powered,"radar should be powered"); check(#r.Cells==0,"clear weather should have no cells")
 state.data.Weather.Precipitation=0.7; r=WeatherRadar.new(state):Step(); check(#r.Cells>=1,"precipitation should create a cell"); check(r.Cells[1].Type=="PRECIPITATION","precipitation cell type mismatch")
 state.data.Weather.Thunderstorm=true; r=WeatherRadar.new(state):Step(); check(r.Cells[1].Type=="STORM","thunderstorm should produce storm cell")
 state.data.Weather.Turbulence=0.8; r=WeatherRadar.new(state):Step(); check(#r.Cells==2,"high turbulence should add a second cell"); check(r.Cells[2].Type=="TURBULENCE","turbulence cell type mismatch")
 state.data.Weather.VisibilityKm=1000; r=WeatherRadar.new(state):Step(); check(r.RangeKm==80,"radar range upper clamp failed")
 state.data.Weather.VisibilityKm=0; r=WeatherRadar.new(state):Step(); check(r.RangeKm==2,"radar range lower clamp failed")
 return true
end
return {Run=run}
