-- FlightSim hydraulic system v0.1
-- Simulation approximation of dual hydraulic system pressure generation and decay.
local Hydraulic={}; Hydraulic.__index=Hydraulic
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Hydraulic.new(state,config) return setmetatable({state=state,config=config},Hydraulic) end
function Hydraulic:Step(dt)
 local x=self.state:Get(); local h=x.Hydraulic or {}; local f=x.Failures and x.Failures.Hydraulic or {}
 local maxP=(self.config and self.config.HydraulicMax) or 3000
 local engines=x.Engines or {}
 local running1=engines[1] and engines[1].Running==true
 local running2=engines[2] and engines[2].Running==true
 local sourceA=running1 or running2
 local sourceB=running1 or running2
 local rate=maxP*0.38
 local decay=maxP*0.18
 h.A=clamp((h.A or 0)+(sourceA and rate or -decay)*dt,0,maxP)
 h.B=clamp((h.B or 0)+(sourceB and rate or -decay)*dt,0,maxP)
 if f.A then h.A=0 end
 if f.B then h.B=0 end
 x.HydraulicState=x.HydraulicState or {}
 x.HydraulicState.A=h.A; x.HydraulicState.B=h.B
 x.HydraulicState.AvailableA=h.A>500
 x.HydraulicState.AvailableB=h.B>500
 x.HydraulicState.Total=h.A+h.B
 x.HydraulicState.FailureA=f.A==true
 x.HydraulicState.FailureB=f.B==true
end
return Hydraulic
