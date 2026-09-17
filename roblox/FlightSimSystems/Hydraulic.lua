-- FlightSim hydraulic system v0.7
-- Simulation approximation of dual hydraulic pressure, electric backup and actuator demand.
-- Hydraulic pressure is normalized through subsystem consumers; A/B remain independently failure-isolated.
local Hydraulic={}; Hydraulic.__index=Hydraulic
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Hydraulic.new(state,config) return setmetatable({state=state,config=config},Hydraulic) end
function Hydraulic:Step(dt)
 local x=self.state:Get(); local h=x.Hydraulic or {}; x.Hydraulic=h; local f=x.Failures and x.Failures.Hydraulic or {}
 local maxP=math.max(1,(self.config and self.config.HydraulicMax) or 3000); dt=clamp(tonumber(dt) or 0,0,0.25)
 local engines=x.Engines or {}; local e=x.Electrical or {}; local raw=x.HydraulicDemand or {}; x.HydraulicDemand=raw
 local running1=engines[1] and engines[1].Running==true; local running2=engines[2] and engines[2].Running==true; local bus1=e.Bus1==true; local bus2=e.Bus2==true
 local fc=clamp(tonumber(raw.FlightControls) or 0,0,1); local gear=clamp(tonumber(raw.LandingGear) or 0,0,1); local brakes=clamp(tonumber(raw.Brakes) or 0,0,1)
 -- FlightControls may publish asymmetric A/B demand. Preserve it and add landing-gear/brake demand
 -- instead of replacing the subsystem's allocation with a symmetric aggregate.
 local controlA=clamp(tonumber(raw.A) or fc,0,1); local controlB=clamp(tonumber(raw.B) or fc,0,1)
 local gearA=gear*0.30; local gearB=gear*0.30; local brakeA=brakes*0.20; local brakeB=brakes*0.20
 local demandA=clamp(math.max(controlA,fc*0.50)+gearA+brakeA,0,1); local demandB=clamp(math.max(controlB,fc*0.50)+gearB+brakeB,0,1)
 local function stepPressure(current,engineSource,electricSource,failed,demand)
  if failed then return 0 end
  local generation=(engineSource and maxP*0.38 or 0)+(electricSource and maxP*0.18 or 0); local load=clamp(demand,0,1)*maxP*0.32; local passiveDecay=maxP*0.06
  return clamp((tonumber(current) or 0)+(generation-load-passiveDecay)*dt,0,maxP)
 end
 h.A=stepPressure(h.A,running1,bus1,f.A==true,demandA); h.B=stepPressure(h.B,running2,bus2,f.B==true,demandB)
 raw.Total=clamp((demandA+demandB)*0.5,0,1); raw.A=demandA; raw.B=demandB
 x.HydraulicState=x.HydraulicState or {}; local hs=x.HydraulicState
 hs.A=h.A; hs.B=h.B; hs.AvailableA=h.A>500; hs.AvailableB=h.B>500; hs.Total=h.A+h.B; hs.FailureA=f.A==true; hs.FailureB=f.B==true; hs.DemandA=demandA; hs.DemandB=demandB
 hs.DemandBreakdown={FlightControls=fc,FlightControlsA=controlA,FlightControlsB=controlB,LandingGear=gear,Brakes=brakes,Total=raw.Total}
 hs.SourceA=(f.A==true and "FAILED") or (running1 and bus1 and "ENG1+ELEC") or (running1 and "ENG1") or (bus1 and "ELEC") or "NONE"
 hs.SourceB=(f.B==true and "FAILED") or (running2 and bus2 and "ENG2+ELEC") or (running2 and "ENG2") or (bus2 and "ELEC") or "NONE"
end
return Hydraulic
