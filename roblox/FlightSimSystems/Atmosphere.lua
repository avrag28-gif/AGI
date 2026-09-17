-- Shared ISA atmosphere helper v1.0
-- Public-physics approximation used consistently by engine, physics and envelope.
local Atmosphere={}
local FT_TO_M=0.3048
local R=287.05287
local GAMMA=1.4
local G=9.80665
local T0=288.15
local P0=101325
local LAPSE=-0.0065
local TROPOPAUSE_M=11000
local STRAT_TEMP_K=216.65
local STRAT_P_PA=22632.06
local KTS_TO_MS=0.514444

local function finite(v,d)
 v=tonumber(v)
 return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end

function Atmosphere.ISATemperatureK(altitudeFt)
 local h=math.max(0,finite(altitudeFt,0))*FT_TO_M
 if h<=TROPOPAUSE_M then return T0+LAPSE*h end
 return STRAT_TEMP_K
end

function Atmosphere.ISATemperatureC(altitudeFt)
 return Atmosphere.ISATemperatureK(altitudeFt)-273.15
end

function Atmosphere.State(altitudeFt,temperatureC)
 local h=math.max(0,finite(altitudeFt,0))*FT_TO_M
 local isaK=Atmosphere.ISATemperatureK(altitudeFt)
 local pressure
 if h<=TROPOPAUSE_M then
  pressure=P0*(isaK/T0)^(-G/(LAPSE*R))
 else
  pressure=STRAT_P_PA*math.exp(-G*(h-TROPOPAUSE_M)/(R*STRAT_TEMP_K))
 end
 local tempK=math.max(150,finite(temperatureC,isaK-273.15)+273.15)
 local density=pressure/(R*tempK)
 local speedOfSound=math.sqrt(GAMMA*R*tempK)
 return {TemperatureC=tempK-273.15,ISATemperatureC=isaK-273.15,PressurePa=pressure,DensityKgM3=density,SpeedOfSoundMS=speedOfSound,SpeedOfSoundKts=speedOfSound/KTS_TO_MS}
end

function Atmosphere.MachFromKts(airspeedKts,altitudeFt,temperatureC)
 local a=Atmosphere.State(altitudeFt,temperatureC)
 return math.max(0,finite(airspeedKts,0)/math.max(a.SpeedOfSoundKts,1))
end

return Atmosphere
