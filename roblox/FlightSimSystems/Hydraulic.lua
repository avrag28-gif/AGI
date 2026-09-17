-- FlightSim hydraulic system v1.0
-- State contract: Hydraulic.A/B/Standby are structured hydraulic-system records.
local Hydraulic={}; Hydraulic.__index=Hydraulic
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensureSystem(h,key)
 local v=h[key]
 if type(v)~="table" then v={Pressure=tonumber(v) or 0,Quantity=1,PumpDemand=0,ElectricPump=false,EnginePump=false,Available=false,Overheat=false}; h[key]=v end
 return v
end
function Hydraulic.new(state,config) return setmetatable({state=state,config=config},Hydraulic) end
function Hydraulic:Step(dt)
 local x=self.state:Get(); local h=x.Hydraulic or {}; x.Hydraulic=h; local f=x.Failures and x.Failures.Hydraulic or {}
 local maxP=math.max(1,(self.config and self.config.HydraulicMax) or 3000); dt=clamp(tonumber(dt) or 0,0,0.25)
 local A=ensureSystem(h,"A"); local B=ensureSystem(h,"B"); local standby=ensureSystem(h,"Standby")
 local engines=x.Engines or {}; local e=x.Electrical or {}; local raw=x.HydraulicDemand or {}; x.HydraulicDemand=raw
 local running1=engines[1] and engines[1].Running==true; local running2=engines[2] and engines[2].Running==true; local bus1=e.Bus1==true; local bus2=e.Bus2==true
 local fc=clamp(tonumber(raw.FlightControls) or 0,0,1); local gear=clamp(tonumber(raw.LandingGear) or 0,0,1); local brakes=clamp(tonumber(raw.Brakes) or 0,0,1)
 local controlA=clamp(tonumber(raw.FlightControlsA) or fc,0,1); local controlB=clamp(tonumber(raw.FlightControlsB) or fc,0,1)
 local demandA=clamp(controlA+gear*0.30+brakes*0.20,0,1); local demandB=clamp(controlB+gear*0.30+brakes*0.20,0,1)
 local function stepSystem(system,engineSource,electricSource,failed,demand)
  system.EnginePump=engineSource; system.ElectricPump=electricSource; system.PumpDemand=clamp(demand,0,1)
  if failed then system.Pressure=0; system.Available=false; return end
  local generation=(engineSource and maxP*0.38 or 0)+(electricSource and maxP*0.18 or 0); local load=system.PumpDemand*maxP*0.32; local passiveDecay=maxP*0.06
  system.Pressure=clamp((tonumber(system.Pressure) or 0)+(generation-load-passiveDecay)*dt,0,maxP); system.Available=system.Pressure>500; system.Overheat=system.PumpDemand>0.95 and system.Pressure<800
 end
 stepSystem(A,running1,bus1,f.A==true,demandA); stepSystem(B,running2,bus2,f.B==true,demandB)
 standby.EnginePump=false; standby.ElectricPump=(bus1 or bus2); standby.PumpDemand=clamp(tonumber(raw.Standby) or 0,0,1); standby.Pressure=clamp((tonumber(standby.Pressure) or 0)+((standby.ElectricPump and maxP*0.22 or 0)-standby.PumpDemand*maxP*0.25-maxP*0.04)*dt,0,maxP); standby.Available=standby.Pressure>500
 raw.Total=clamp((demandA+demandB)*0.5,0,1); raw.A=demandA; raw.B=demandB
 x.HydraulicState=x.HydraulicState or {}; local hs=x.HydraulicState
 hs.A=A.Pressure; hs.B=B.Pressure; hs.Standby=standby.Pressure; hs.AvailableA=A.Available; hs.AvailableB=B.Available; hs.AvailableStandby=standby.Available; hs.Total=A.Pressure+B.Pressure; hs.FailureA=f.A==true; hs.FailureB=f.B==true; hs.DemandA=demandA; hs.DemandB=demandB
 hs.DemandBreakdown={FlightControls=fc,FlightControlsA=controlA,FlightControlsB=controlB,LandingGear=gear,Brakes=brakes,Total=raw.Total}
 hs.SourceA=(f.A==true and "FAILED") or (running1 and bus1 and "ENG1+ELEC") or (running1 and "ENG1") or (bus1 and "ELEC") or "NONE"
 hs.SourceB=(f.B==true and "FAILED") or (running2 and bus2 and "ENG2+ELEC") or (running2 and "ENG2") or (bus2 and "ELEC") or "NONE"
 return true
end
return Hydraulic
