-- FlightSim electrical system v0.6
-- Simulation approximation of source priority, bus transfer, battery reserve and load shedding.
local Electrical={}; Electrical.__index=Electrical
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.Electrical=x.Electrical or {}
 x.Electrical.Bus1=x.Electrical.Bus1==true; x.Electrical.Bus2=x.Electrical.Bus2==true
 x.Electrical.LoadShed=x.Electrical.LoadShed or {NonEssential=false,Display=false,Avionics=false}
 x.BatteryCharge=clamp(tonumber(x.BatteryCharge) or 1,0,1)
end
function Electrical.new(state) return setmetatable({state=state},Electrical) end
function Electrical:Step(dt)
 local x=self.state:Get(); ensure(x); local e=x.Electrical; local f=x.Failures and x.Failures.Electrical or {}
 local eng1=x.Engines[1]; local eng2=x.Engines[2]
 local ext=e.ExternalPower==true
 local apuGen=e.APU==true and f.APU~=true and x.APU and x.APU.GeneratorAvailable==true
 local g1=eng1.GeneratorAvailable==true and f.Bus1~=true
 local g2=eng2.GeneratorAvailable==true and f.Bus2~=true
 local battery=e.Battery==true and x.BatteryCharge>0
 local bus1Available=f.Bus1~=true and (ext or apuGen or g1 or battery)
 local bus2Available=f.Bus2~=true and (ext or apuGen or g2 or battery)
 e.Bus1=bus1Available; e.Bus2=bus2Available
 local both=bus1Available and bus2Available
 local primary=ext or apuGen or g1 or g2
 if battery and not primary then x.BatteryCharge=clamp(x.BatteryCharge-0.006*math.max(0,dt),0,1)
 elseif battery and primary then x.BatteryCharge=clamp(x.BatteryCharge+0.0008*math.max(0,dt),0,1) end
 if x.BatteryCharge<=0 then e.Battery=false; battery=false; e.Bus1=f.Bus1~=true and (ext or apuGen or g1); e.Bus2=f.Bus2~=true and (ext or apuGen or g2) end
 local shed=not (e.Bus1 and e.Bus2) or (e.Battery and not primary)
 e.LoadShed.NonEssential=shed; e.LoadShed.Display=not (e.Bus1 and e.Bus2); e.LoadShed.Avionics=not e.Bus1 and not e.Bus2
 x.ElectricalState=x.ElectricalState or {}
 x.ElectricalState.Source1=(ext and "EXTERNAL") or (apuGen and "APU_GEN") or (g1 and "GEN1") or ((e.Battery and x.BatteryCharge>0) and "BATTERY") or "NONE"
 x.ElectricalState.Source2=(ext and "EXTERNAL") or (apuGen and "APU_GEN") or (g2 and "GEN2") or ((e.Battery and x.BatteryCharge>0) and "BATTERY") or "NONE"
 x.ElectricalState.APUGenerator=apuGen==true
 x.ElectricalState.Generator1=g1==true; x.ElectricalState.Generator2=g2==true
 x.ElectricalState.ExternalPower=ext
 x.ElectricalState.BatteryConnected=e.Battery==true
 x.ElectricalState.BatteryCharge=x.BatteryCharge
 x.ElectricalState.DualBus=e.Bus1==true and e.Bus2==true
 x.ElectricalState.LoadShed=shed
end
return Electrical
