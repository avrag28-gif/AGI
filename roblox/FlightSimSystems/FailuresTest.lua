-- FlightSim failure manager deterministic contract tests v0.1
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Engines={[1]={Running=true,FuelOn=true,Ignition=true,Starter=true,Thrust=50000,GeneratorAvailable=true},[2]={Running=true,FuelOn=true,Ignition=true,Starter=true,Thrust=50000,GeneratorAvailable=true}},Electrical={Bus1=true,Bus2=true,APU=true},Hydraulic={A=3000,B=3000}})
 FailureSchema.Apply(s.data)
 local f=Failures.new(s)
 check(f:SetEngine(1,true,"TEST") and s.data.Failures.Engines[1].Reason=="TEST","engine failure setter failed")
 f:Step(1); check(not s.data.Engines[1].Running and s.data.Engines[1].Thrust==0,"engine failure was not propagated")
 check(f:SetElectrical("Bus1",true),"electrical failure setter failed"); f:Step(1); check(not s.data.Electrical.Bus1,"Bus1 failure was not propagated")
 check(f:SetHydraulic("A",true),"hydraulic failure setter failed"); f:Step(1); check(s.data.Hydraulic.A==0,"hydraulic A failure was not propagated")
 check(f:SetAntiIce("Wing",true),"anti-ice failure setter failed"); check(s.data.Failures.AntiIce.Wing==true,"anti-ice failure state missing")
 return true
end
return {Run=run}
