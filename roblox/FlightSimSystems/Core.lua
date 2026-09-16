-- FlightSim aircraft core systems integration v0.4
local Core={}; Core.__index=Core
function Core.new(state) return setmetatable({state=state},Core) end
function Core:Step(dt)
 local x=self.state:Get(); local e=x.Electrical; local f=x.Failures or {}
 local engine1=x.Engines[1]; local engine2=x.Engines[2]
 -- Electrical.lua and Hydraulic.lua own their respective physical outputs.
 -- Core only publishes shared aircraft-level power state and handles fuel.
 local powered=(e.Bus1==true or e.Bus2==true)
 x.Avionics.IRS=powered; x.Avionics.FMC=powered; x.Avionics.Radios=powered; x.Avionics.Transponder=powered; x.Avionics.TCAS=powered
 if f.Electrical and f.Electrical.Bus1 and f.Electrical.Bus2 then
  x.Avionics.IRS=false; x.Avionics.FMC=false; x.Avionics.Radios=false; x.Avionics.Transponder=false; x.Avionics.TCAS=false
 end
 local totalFlow=0
 for _,engine in pairs(x.Engines) do if engine.Running and engine.FuelOn then totalFlow+=math.max(0,engine.FuelFlow) end end
 if totalFlow>0 and x.Fuel.Total>0 then
  local consumed=totalFlow*dt/60
  local center=math.min(x.Fuel.Center,consumed); x.Fuel.Center-=center; consumed-=center
  if consumed>0 then
   local wingTotal=x.Fuel.Left+x.Fuel.Right
   if wingTotal>0 then local leftShare=consumed*x.Fuel.Left/wingTotal; local rightShare=consumed-leftShare; x.Fuel.Left=math.max(0,x.Fuel.Left-leftShare); x.Fuel.Right=math.max(0,x.Fuel.Right-rightShare) end
  end
 end
 x.Fuel.Total=math.max(0,x.Fuel.Left+x.Fuel.Center+x.Fuel.Right)
 x.SystemHealth=x.SystemHealth or {}
 x.SystemHealth.Electrical=powered
 x.SystemHealth.HydraulicA=(x.Hydraulic.A or 0)>500
 x.SystemHealth.HydraulicB=(x.Hydraulic.B or 0)>500
end
return Core
