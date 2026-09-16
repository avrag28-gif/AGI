-- FlightSim aircraft core systems integration v0.5
local Core={}; Core.__index=Core
function Core.new(state) return setmetatable({state=state},Core) end
function Core:Step(dt)
 local x=self.state:Get(); local e=x.Electrical; local f=x.Failures or {}
 -- Core publishes shared aircraft-level power state. Fuel ownership is delegated to Fuel.lua.
 local powered=(e.Bus1==true or e.Bus2==true)
 x.Avionics.IRS=powered; x.Avionics.FMC=powered; x.Avionics.Radios=powered; x.Avionics.Transponder=powered; x.Avionics.TCAS=powered
 if f.Electrical and f.Electrical.Bus1 and f.Electrical.Bus2 then
  x.Avionics.IRS=false; x.Avionics.FMC=false; x.Avionics.Radios=false; x.Avionics.Transponder=false; x.Avionics.TCAS=false
 end
 x.SystemHealth=x.SystemHealth or {}
 x.SystemHealth.Electrical=powered
 x.SystemHealth.HydraulicA=(x.Hydraulic.A or 0)>500
 x.SystemHealth.HydraulicB=(x.Hydraulic.B or 0)>500
 x.SystemHealth.Fuel=(x.Fuel.Total or 0)>0
end
return Core
