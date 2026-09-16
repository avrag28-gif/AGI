-- Compatibility contract for AntiIce v0.2
-- Supersedes AntiIceTest.lua when running the v0.2 dependency chain.
local AntiIce=require(script.Parent.AntiIce)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Environment={Icing=0.8},Electrical={Bus1=true,Bus2=false,APU=false},Engines={[1]={Running=true},[2]={Running=true}},BleedAir={SourceAvailable=true},Failures={Engines={[1]={Active=false},[2]={Active=false}},AntiIce={Engine1=false,Engine2=false,Wing=false}},WeatherEffects={IcingDragFactor=1,IcingLiftFactor=1}})
 local a=AntiIce.new(s); a:Step(1); check(a.IcingDemand==0.8,"icing demand mismatch"); check(a.Engine1Available and a.Engine2Available,"running engines with bleed should be available")
 a:SetEngine(1,true); a:SetEngine(2,true); a:SetWing(true); a:Step(1); check(a.IceProtection==1,"all anti-ice zones should provide full modelled protection"); check(s.data.WeatherEffects.IcingResidual==0,"protected icing should have no residual icing")
 s.data.Failures.Engines[1].Active=true; a:Step(1); check(not a.Engine1,"failed engine anti-ice must disengage"); check(a.Engine2,"healthy engine anti-ice should remain engaged")
 s.data.Failures.AntiIce.Engine2=true; a:Step(1); check(not a.Engine2 and a.Warning,"anti-ice component failure should disengage and warn")
 s.data.Failures.AntiIce.Engine2=false; s.data.BleedAir.SourceAvailable=false; a:Step(1); check(not a.Engine2 and not a.Wing,"anti-ice must drop without bleed source")
 return true
end
return {Run=run}
