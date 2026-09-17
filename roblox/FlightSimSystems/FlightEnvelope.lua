-- Flight envelope helper v1.3
-- Simulation approximation: derives load-factor/stall/overspeed indicators from
-- current mass, atmosphere and configurable aerodynamic tuning. It is not an AFM/FCOM.
local Profile=require(script.Parent.AircraftProfile)
local Atmosphere=require(script.Parent.Atmosphere)
local Envelope={}
local KTS_TO_MS=0.514444
local G=9.80665
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v,d)
 v=tonumber(v)
 return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end
function Envelope.Calculate(state)
 state=state or {}
 local wb=state.WeightBalance or {}
 local mass=math.max(finite(wb.GrossMassKg,finite(state.Mass,Profile.Weights.OperatingEmptyMassKg)),1)
 local altitude=math.max(finite(state.Altitude,0),0)
 local environment=state.Environment or {}
 local temp=finite(environment.TemperatureC,Atmosphere.ISATemperatureC(altitude))
 local atm=Atmosphere.State(altitude,temp)
 local rho=math.max(atm.DensityKgM3,0.01)
 local sound=atm.SpeedOfSoundMS
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
 local stallThresholdKt=math.max(stallKt,acceleratedStallKt)
 local airspeed=math.max(finite(state.Airspeed,0),0)
 -- Physics stores Airspeed as a TAS-like aerodynamic speed. VMO is a KCAS limit,
 -- so comparing raw TAS against VMO would make the high-altitude overspeed gate wrong.
 -- This uses EAS as a stable public-physics approximation for the CAS gate; MMO is
 -- checked independently from Mach. The distinction is intentionally exposed in state.
 local densityRatio=clamp(rho/1.225,0.01,1.25)
 local equivalentAirspeedKt=airspeed*math.sqrt(densityRatio)
 local vmo=finite(Profile.Limits.VMOKcas,340)
 local mach=math.max(finite(state.Mach,airspeed/math.max(atm.SpeedOfSoundKts,1)),0)
 local mmo=finite(Profile.Limits.MMO,0.82)
 local airborne=state.GroundContact~=true
 local stallWarning=airborne and airspeed<=stallThresholdKt*1.10
 local stallActive=airborne and airspeed<=stallThresholdKt
 local vmoOverspeed=equivalentAirspeedKt>vmo
 local machOverspeed=mach>mmo
 return {
  StallSpeedKt=stallKt,
  AcceleratedStallSpeedKt=acceleratedStallKt,
  StallThresholdKt=stallThresholdKt,
  StallMarginKt=airspeed-stallThresholdKt,
  StallMarginPercent=(airspeed/math.max(stallThresholdKt,1)-1)*100,
  StallWarning=stallWarning,
  StallActive=stallActive,
  Overspeed=vmoOverspeed or machOverspeed,
  VMO=vmo,
  MMO=mmo,
  Mach=mach,
  DensityKgM3=rho,
  DensityRatio=densityRatio,
  EquivalentAirspeedKt=equivalentAirspeedKt,
  VMOOverspeed=vmoOverspeed,
  MMOOverspeed=machOverspeed,
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
