-- FlightSim cross-system failure propagation contract tests v0.2
-- Verifies one-way ownership: Failures declares the fault; subsystems apply physical consequences.
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local Engine=require(script.Parent.Engine)
local BleedAir=require(script.Parent.BleedAir)
local AntiIce=require(script.Parent.AntiIce)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Engines={[1]={Running=true,N2=60,N1=70,FuelOn=true,Ignition=true,Starter=false,Thrust=50000,GeneratorAvailable=true},[2]={Running=true,N2=60,N1=70,FuelOn=true,Ignition=true,Starter=false,Thrust=50000,GeneratorAvailable=true}},
  APU={Running=true,GeneratorAvailable=true,RPM=95},
  Electrical={Bus1=true,Bus2=true,APU=true},
  Failures={},
  Environment={Icing=0.8},
  WeatherEffects={IcingDragFactor=1,IcingLiftFactor=1},
 })
 FailureSchema.Apply(s.data)
 local failures=Failures.new(s); local engine=Engine.new(s); local bleed=BleedAir.new(s); local ice=AntiIce.new(s)
 s.data.Failures.Engines[1].Active=true
 failures:Step(1)
 check(s.data.Engines[1].Running==true and s.data.Engines[1].Thrust==50000,"failure manager must not own engine physics")
 check(s.data.FailureEffects.Engine1Failed==true,"engine failure effect missing")
 engine:Step(1); bleed:Step(1); ice:Step(1)
 check(s.data.Engines[1].Running==false,"failed engine must be shut down by Engine")
 check(s.data.Engines[1].Thrust==0,"failed engine thrust must be zero")
 check(s.data.BleedAir.Engine1Source==false,"failed engine must lose bleed source")
 check(s.data.BleedAir.Engine2Source==true,"healthy engine must retain bleed source")
 s.data.Failures.AntiIce.Engine2=true; ice:SetEngine(2,true); ice:Step(1)
 check(not s.data.AntiIce.Engine2 and s.data.AntiIce.Warning,"failed anti-ice component must disengage and warn")
 return true
end
return {Run=run}
