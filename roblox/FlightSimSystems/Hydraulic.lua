-- FlightSim hydraulic system v0.2
-- Simulation approximation of dual hydraulic system pressure generation, electric backup and decay.
local Hydraulic={}; Hydraulic.__index=Hydraulic
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Hydraulic.new(state,config) return setmetatable({state=state,config=config},Hydraulic) end
function Hydraulic:Step(dt)
 local x=self.state:Get(); local h=x.Hydraulic or {}; local f=x.Failures and x.Failures.Hydraulic or {}
 local maxP=(self.config and self.config.HydraulicMax) or 3000
 local engines=x.Engines or {}
 local running1=engines[1] and engines[1].Running==true
 local running2=engines[2] and engines[2].Running==true
 local elec=x.Electrical or {}
 local bus1=elec.Bus1==true
 local bus2=elec.Bus2==true
 local sourceA=running1 or bus1
 local sourceB=running2 or bus2
 local rate=maxP*0.38
 local electricRate=maxP*0.18
 local decay=maxP*0.18
 local function stepPressure(current,engineSource,electricSource,failed)
  if failed then return 0 end
  local generation=0
  if engineSource then generation+=rate end
  if electricSource then generation+=electricRate end
  if generation>0 then return clamp((current or 0)+generation*dt,0,maxP) end
  return clamp((current or 0)-decay*dt,0,maxP)
 end
 h.A=stepPressure(h.A,running1,bus1,f.A==true)
 h.B=stepPressure(h.B,running2,bus2,f.B==true)
 x.HydraulicState=x.HydraulicState or {}
 x.HydraulicState.A=h.A; x.HydraulicState.B=h.B
 x.HydraulicState.AvailableA=h.A>500
 x.HydraulicState.AvailableB=h.B>500
 x.HydraulicState.Total=h.A+h.B
 x.HydraulicState.FailureA=f.A==true
 x.HydraulicState.FailureB=f.B==true
 x.HydraulicState.SourceA=(f.A==true and "FAILED") or (running1 and bus1 and "ENG1+ELEC") or (running1 and "ENG1") or (bus1 and "ELEC") or "NONE"
 x.HydraulicState.SourceB=(f.B==true and "FAILED") or (running2 and bus2 and "ENG2+ELEC") or (running2 and "ENG2") or (bus2 and "ELEC") or "NONE"
end
return Hydraulic
