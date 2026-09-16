-- FlightSim weather radar presentation model v0.1
-- Game-simulation weather returns; not a certified airborne weather radar model.
local WeatherRadar={}; WeatherRadar.__index=WeatherRadar
local function finite(v,d) v=tonumber(v); if not v or v~=v or v==math.huge or v==-math.huge then return d end; return v end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function WeatherRadar.new(state) return setmetatable({state=state},WeatherRadar) end
function WeatherRadar:Step()
 local x=self.state:Get(); local w=x.Weather or {}; local powered=(x.Avionics and x.Avionics.WeatherRadar==true) or false; local visibility=math.max(finite(w.VisibilityKm,50),0); local precipitation=clamp(finite(w.Precipitation,0),0,1); local turbulence=clamp(finite(w.Turbulence,0),0,1); local storm=w.Thunderstorm==true; local maxRange=math.clamp(visibility*1.5,2,80); local intensity=clamp(precipitation*0.8+(storm and 0.2 or 0),0,1); local cells={}
 if powered and intensity>0 then cells[1]={BearingDeg=finite(w.WindDirection,0),RangeKm=clamp(maxRange*(0.35+0.45*intensity),2,maxRange),Intensity=intensity,Type=storm and "STORM" or "PRECIPITATION"}; if turbulence>0.6 then cells[2]={BearingDeg=(finite(w.WindDirection,0)+55)%360,RangeKm=maxRange*0.65,Intensity=clamp(turbulence,0,1),Type="TURBULENCE"} end end
 local r={Powered=powered,RangeKm=maxRange,VisibilityKm=visibility,Precipitation=precipitation,Turbulence=turbulence,Thunderstorm=storm,Cells=cells}; x.WeatherRadar=r; return r
end
return WeatherRadar
