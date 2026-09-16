-- FlightSim hydraulic system v0.3
-- Simulation approximation of dual hydraulic pressure, electric backup and actuator demand.
local Hydraulic={}; Hydraulic.__index=Hydraulic
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Hydraulic.new(state,config) return setmetatable({state=state,config=config},Hydraulic) end
function Hydraulic:Step(dt)
 local x=self.state:Get(); local h=x.Hydraulic or {}; local f=x.Failures and x.Failures.Hydraulic or {}
 local maxP=(self.config and self.config.HydraulicMax) or 3000
 local engines=x.Engines or {}; local e=x.Electrical or {}
 local running1=engines[1] and engines[1].Running==true; local running2=engines[2] and engines[2].Running==true
 local bus1=e.Bus1==true; local bus2=e.Bus2==true
 local demand=x.HydraulicDemand or {}
 local function stepPressure(current,engineSource,electricSource,failed,demandValue)
  if failed then return 0 end
  local generation=(engineSource and maxP*0.38 or 0)+(electricSource and maxP*0.18 or 0)
  local load=clamp(tonumber(demandValue) or 0,0,1)*maxP*0.32
  local passiveDecay=maxP*0.06
  return clamp((current or 0)+(generation-load-passiveDecay)*dt,0,maxP)
 end
 h.A=stepPressure(h.A,running1,bus1,f.A==true,demand.A)
 h.B=stepPressure(h.B,running2,bus2,f.B==true,demand.B)
 x.HydraulicState=x.HydraulicState or {}
 x.HydraulicState.A=h.A; x.HydraulicState.B=h.B
 x.HydraulicState.AvailableA=h.A>500; x.HydraulicState.AvailableB=h.B>500
 x.HydraulicState.Total=h.A+h.B
 x.HydraulicState.FailureA=f.A==true; x.HydraulicState.FailureB=f.B==true
 x.HydraulicState.DemandA=clamp(tonumber(demand.A) or 0,0,1); x.HydraulicState.DemandB=clamp(tonumber(demand.B) or 0,0,1)
 x.HydraulicState.SourceA=(f.A==true and "FAILED") or (running1 and bus1 and "ENG1+ELEC") or (running1 and "ENG1") or (bus1 and "ELEC") or "NONE"
 x.HydraulicState.SourceB=(f.B==true and "FAILED") or (running2 and bus2 and "ENG2+ELEC") or (running2 and "ENG2") or (bus2 and "ELEC") or "NONE"
end
return Hydraulic
