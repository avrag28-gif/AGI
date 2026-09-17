-- Flight envelope helper v1.2
-- Simulation approximation: derives load-factor/stall/overspeed indicators from
-- current mass, atmosphere and configurable aerodynamic tuning. It is not an AFM/FCOM.
local Profile=require(script.Parent.AircraftProfile)
local Envelope={}
local FT_TO_M=0.3048
local KTS_TO_MS=0.514444
local G=9.80665
local R=287.05287
local GAMMA=1.4
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v,d)
 v=tonumber(v)
 return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end
local function atmosphere(altitudeFt,tempC)
 local h=math.max(0,finite(altitudeFt,0))*FT_TO_M
 local T=math.max(150,finite(tempC,15)+273.15)
 local Tisa=288.15
 local P0=101325
 local lapse=-0.0065
 local p
 if h<=11000 then
  local Ti=Tisa+lapse*h
  p=P0*(Ti/Tisa)^(-G/(lapse*R))
 else
  p=22632.06*math.exp(-G*(h-11000)/(R*216.65))
 end
 local rho=p/(R*T)
 local a=math.sqrt(GAMMA*R*T)
 return math.max(rho,0.01),a
end
function Envelope.Calculate(state)
 state=state or {}
 local wb=state.WeightBalance or {}
 local mass=math.max(finite(wb.GrossMassKg,finite(state.Mass,Profile.Weights.OperatingEmptyMassKg)),1)
 local altitude=math.max(finite(state.Altitude,0),0)
 local temp=finite((state.Environment or {}).TemperatureC,15-1.9812*math.min(altitude,36089)/1000)
 local rho,sound=atmosphere(altitude,temp)
 local flap=clamp(finite((state.Surface or {}).Flap,0),0,1)
 local icing=clamp(finite((state.WeatherEffects or {}).IcingLiftFactor,1),0.88,1)
 local wingArea=125
 local cleanCLmax=1.50
 local flapCLgain=0.32*flap
 local clMax=(cleanCLmax+flapCLgain)*icing
 local weight=mass*G
 local stallMs=math.sqrt(2*weight/(rho*wingArea*math.max(clMax,0.5)))
 local stallKt=stallMs/KTS_TO_MS
 local loadFactor=math.max(finite(state.LoadFactor,1),0.01)
 local acceleratedStallKt=stallKt*math.sqrt(loadFactor)
 -- The maneuvering stall threshold is only above the 1-g threshold when
 -- positive load factor exceeds 1. This keeps the warning useful in turns
 -- without allowing low/negative load-factor values to create an artificial
 -- near-zero stall threshold.
 local stallThresholdKt=math.max(stallKt,acceleratedStallKt)
 local airspeed=math.max(finite(state.Airspeed,0),0)
 local vmo=finite(Profile.Limits.VMOKcas,340)
 local mach=math.max(finite(state.Mach,0),0)
 local mmo=finite(Profile.Limits.MMO,0.82)
 local airborne=state.GroundContact~=true
 local stallWarning=airborne and airspeed<=stallThresholdKt*1.10
 local stallActive=airborne and airspeed<=stallThresholdKt
 return {
  StallSpeedKt=stallKt,
  AcceleratedStallSpeedKt=acceleratedStallKt,
  StallThresholdKt=stallThresholdKt,
  StallMarginKt=airspeed-stallThresholdKt,
  StallMarginPercent=(airspeed/math.max(stallThresholdKt,1)-1)*100,
  StallWarning=stallWarning,
  StallActive=stallActive,
  Overspeed=airspeed>vmo or mach>mmo,
  VMO=vmo,
  MMO=mmo,
  Mach=mach,
  DensityKgM3=rho,
  SpeedOfSoundMS=sound,
  CLMax=clMax,
  Airborne=airborne,
 }
end
function Envelope.Step(state)
 local result=Envelope.Calculate(state)
 state.FlightEnvelope=result
 state.StallWarning=result.StallWarning
 state.StallActive=result.StallActive
 state.OverspeedWarning=result.Overspeed
 return result
end
return Envelope
