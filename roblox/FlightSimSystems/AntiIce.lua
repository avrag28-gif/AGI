-- FlightSim anti-ice system v0.1
-- Game-simulation model; this is not a certified Boeing/engine anti-ice model.
local AntiIce={}; AntiIce.__index=AntiIce
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.AntiIce=x.AntiIce or {Engine1=false,Engine2=false,Wing=false,Engine1Available=false,Engine2Available=false,WingAvailable=false,IcingDemand=0,IceProtection=0,EnginePenalty={[1]=1,[2]=1},Warning=false}
 return x.AntiIce
end
function AntiIce.new(state) return setmetatable({state=state},AntiIce) end
function AntiIce:SetEngine(index,on) index=tonumber(index); if index~=1 and index~=2 then return false,"invalid_engine" end; local a=ensure(self.state:Get()); a["Engine"..index]=on==true; return true end
function AntiIce:SetWing(on) ensure(self.state:Get()).Wing=on==true; return true end
function AntiIce:Step(dt)
 local x=self.state:Get(); local a=ensure(x); local e1=x.Engines and x.Engines[1] or {}; local e2=x.Engines and x.Engines[2] or {}; local el=x.Electrical or {}; local weather=x.Environment or x.Weather or {}; local icing=clamp(tonumber(weather.Icing) or 0,0,1); local failed=(x.Failures and x.Failures.Engines) or {}
 local power=(el.Bus1==true or el.Bus2==true or el.APU==true)
 a.IcingDemand=icing
 a.Engine1Available=e1.Running==true and not (failed[1] and failed[1].Active)
 a.Engine2Available=e2.Running==true and not (failed[2] and failed[2].Active)
 a.WingAvailable=power and (a.Engine1Available or a.Engine2Available)
 if not a.Engine1Available then a.Engine1=false end
 if not a.Engine2Available then a.Engine2=false end
 if not a.WingAvailable then a.Wing=false end
 local protected=0
 if a.Engine1 and a.Engine1Available then protected+=0.35 end
 if a.Engine2 and a.Engine2Available then protected+=0.35 end
 if a.Wing and a.WingAvailable then protected+=0.30 end
 a.IceProtection=clamp(protected,0,1)
 local residual=clamp(icing*(1-a.IceProtection),0,1)
 a.EnginePenalty[1]=clamp(1-0.08*residual-(a.Engine1 and 0.025 or 0),0.85,1)
 a.EnginePenalty[2]=clamp(1-0.08*residual-(a.Engine2 and 0.025 or 0),0.85,1)
 x.AntiIce=a
 x.WeatherEffects=x.WeatherEffects or {}
 x.WeatherEffects.IcingResidual=residual
 x.WeatherEffects.IcingDragFactor=clamp(1+0.12*residual,1,1.12)
 x.WeatherEffects.IcingLiftFactor=clamp(1-0.10*residual,0.88,1)
 a.Warning=icing>=0.5 and protected<0.25
end
return AntiIce
