-- FlightSim electrical system v0.3
-- Simulation approximation of source priority, bus availability, battery reserve and load shedding.
local Electrical={}; Electrical.__index=Electrical
local function ensure(x)
 x.Electrical=x.Electrical or {}
 x.Electrical.Bus1=x.Electrical.Bus1==true; x.Electrical.Bus2=x.Electrical.Bus2==true
 x.Electrical.LoadShed=x.Electrical.LoadShed or {NonEssential=false,Display=false,Avionics=false}
 x.BatteryCharge=math.max(0,math.min(1,tonumber(x.BatteryCharge) or 1))
end
function Electrical.new(state) return setmetatable({state=state},Electrical) end
function Electrical:Step(dt)
 local x=self.state:Get(); ensure(x); local e=x.Electrical; local f=x.Failures and x.Failures.Electrical or {}
 local eng1=x.Engines[1]; local eng2=x.Engines[2]
 local ext=(e.ExternalPower==true) and not (f.ExternalPower==true)
 local apu=(e.APU==true) and not (f.APU==true)
 local g1=(eng1.GeneratorAvailable==true) and not (f.Bus1==true)
 local g2=(eng2.GeneratorAvailable==true) and not (f.Bus2==true)
 local battery=(e.Battery==true)
 local availablePrimary=ext or apu or g1 or g2
 e.Bus1=not f.Bus1 and (ext or apu or g1 or battery)
 e.Bus2=not f.Bus2 and (ext or apu or g2 or battery)
 local bothBuses=e.Bus1 and e.Bus2
 local batteryOnly=battery and not availablePrimary
 if batteryOnly then x.BatteryCharge=math.max(0,x.BatteryCharge-0.006*dt)
 elseif battery then x.BatteryCharge=math.min(1,x.BatteryCharge+0.0008*dt) end
 if x.BatteryCharge<=0 then e.Battery=false; e.Bus1=not f.Bus1 and (ext or apu or g1); e.Bus2=not f.Bus2 and (ext or apu or g2) end
 local shed=not bothBuses or batteryOnly
 e.LoadShed.NonEssential=shed
 e.LoadShed.Display=not bothBuses
 e.LoadShed.Avionics=not e.Bus1 and not e.Bus2
 x.ElectricalState=x.ElectricalState or {}
 x.ElectricalState.Source1=(ext and "EXTERNAL") or (apu and "APU") or (g1 and "GEN1") or (battery and "BATTERY") or "NONE"
 x.ElectricalState.Source2=(ext and "EXTERNAL") or (apu and "APU") or (g2 and "GEN2") or (battery and "BATTERY") or "NONE"
 x.ElectricalState.BatteryCharge=x.BatteryCharge
 x.ElectricalState.DualBus=bothBuses
 x.ElectricalState.LoadShed=shed
end
return Electrical
