-- FlightSim anti-ice deterministic contract tests v0.2
local AntiIce=require(script.Parent.AntiIce)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Weather={Icing=0.8},
  Electrical={Bus1=true,Bus2=false,APU=false},
  Engines={[1]={Running=true},[2]={Running=true}},
  Failures={Engines={[1]={Active=false},[2]={Active=false}},AntiIce={}},
  BleedAir={SourceAvailable=true},
  WeatherEffects={IcingDragFactor=1,IcingLiftFactor=1}
 })
 local a=AntiIce.new(s); a:Step(1)
 check(a.IcingDemand==0.8,"icing demand mismatch")
 check(a.Engine1Available and a.Engine2Available,"running engines should be available")
 a:SetEngine(1,true); a:SetEngine(2,true); a:SetWing(true); a:Step(1)
 check(a.IceProtection==1,"all anti-ice zones should provide full modelled protection")
 check(s.data.WeatherEffects.IcingResidual==0,"protected icing should have no residual icing")
 s.data.Failures.Engines[1].Active=true; a:Step(1)
 check(not a.Engine1,"failed engine anti-ice must disengage")
 check(a.Engine2,"healthy engine anti-ice should remain engaged")
 s.data.Electrical.Bus1=false; s.data.Electrical.Bus2=false
 a:Step(1)
 check(a.Wing,"wing anti-ice availability depends on bleed source, not electrical bus in this model")
 s.data.BleedAir.SourceAvailable=false; a:Step(1)
 check(not a.Wing,"wing anti-ice must drop without bleed source")
 return true
end
return {Run=run}
