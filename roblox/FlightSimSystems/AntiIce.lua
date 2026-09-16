-- FlightSim anti-ice system v0.2
-- Game-simulation model; this is not a certified Boeing/engine anti-ice model.
local AntiIce={}; AntiIce.__index=AntiIce
local function clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or 0)) end
local function ensure(x)
 x.AntiIce=x.AntiIce or {Engine1=false,Engine2=false,Wing=false,Engine1Available=false,Engine2Available=false,WingAvailable=false,IcingDemand=0,IceProtection=0,EnginePenalty={[1]=1,[2]=1},Warning=false}
 local a=x.AntiIce; a.EnginePenalty=a.EnginePenalty or {[1]=1,[2]=1}; return a
end
function AntiIce.new(state) return setmetatable({state=state},AntiIce) end
function AntiIce:SetEngine(index,on) index=tonumber(index); if index~=1 and index~=2 then return false,"invalid_engine" end; local a=ensure(self.state:Get()); a["Engine"..index]=on==true; return true end
function AntiIce:SetWing(on) ensure(self.state:Get()).Wing=on==true; return true end
function AntiIce:Step(dt)
 local x=self.state:Get(); local a=ensure(x); local e1=x.Engines and x.Engines[1] or {}; local e2=x.Engines and x.Engines[2] or {}; local b=x.BleedAir or {}; local weather=x.Environment or x.Weather or {}; local icing=clamp(weather.Icing,0,1); local failures=x.Failures or {}; local ef=failures.Engines or {}; local af=failures.AntiIce or {}
 local bleedPower=b.SourceAvailable==true
 a.IcingDemand=icing
 a.Engine1Available=e1.Running==true and not (ef[1] and ef[1].Active) and af.Engine1~=true and bleedPower
 a.Engine2Available=e2.Running==true and not (ef[2] and ef[2].Active) and af.Engine2~=true and bleedPower
 a.WingAvailable=bleedPower and af.Wing~=true
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
 a.Warning=(icing>=0.5 and protected<0.25) or (a.Engine1 and not a.Engine1Available) or (a.Engine2 and not a.Engine2Available) or (a.Wing and not a.WingAvailable)
 x.AntiIce=a
 x.WeatherEffects=x.WeatherEffects or {}
 x.WeatherEffects.IcingResidual=residual
 x.WeatherEffects.IcingDragFactor=clamp(1+0.12*residual,1,1.12)
 x.WeatherEffects.IcingLiftFactor=clamp(1-0.10*residual,0.88,1)
end
return AntiIce
