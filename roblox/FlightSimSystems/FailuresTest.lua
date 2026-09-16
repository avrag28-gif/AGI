-- FlightSim failure manager deterministic contract tests v0.2
-- Verifies that Failures owns authoritative failure state/effects and does not hard-overwrite subsystem physics.
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Engines={[1]={Running=true,FuelOn=true,Ignition=true,Starter=true,Thrust=50000,GeneratorAvailable=true},[2]={Running=true,FuelOn=true,Ignition=true,Starter=true,Thrust=50000,GeneratorAvailable=true}},Electrical={Bus1=true,Bus2=true,APU=true},Hydraulic={A=3000,B=3000}})
 FailureSchema.Apply(s.data)
 local f=Failures.new(s)
 check(f:SetEngine(1,true,"TEST") and s.data.Failures.Engines[1].Reason=="TEST","engine failure setter failed")
 f:Step(1)
 check(s.data.Engines[1].Running,"failure manager must not own engine physical state")
 check(s.data.Engines[1].Thrust==50000,"failure manager must not hard-overwrite engine thrust")
 check(s.data.FailureEffects.Engine1Failed,"engine failure effect missing")
 check(f:SetElectrical("Bus1",true),"electrical failure setter failed"); f:Step(1)
 check(s.data.Electrical.Bus1,"failure manager must not hard-overwrite electrical bus state")
 check(s.data.FailureEffects.ElectricalBus1Failed,"electrical failure effect missing")
 check(f:SetHydraulic("A",true),"hydraulic failure setter failed"); f:Step(1)
 check(s.data.Hydraulic.A==3000,"failure manager must not hard-overwrite hydraulic pressure")
 check(s.data.FailureEffects.HydraulicAFailed,"hydraulic failure effect missing")
 check(f:SetFlightControl("Aileron",true),"flight-control failure setter failed"); f:Step(1)
 check(s.data.FailureEffects.AileronAuthority==0,"flight-control failure effect missing")
 check(f:SetAntiIce("Wing",true),"anti-ice failure setter failed"); f:Step(1)
 check(s.data.Failures.AntiIce.Wing==true and s.data.FailureEffects.AntiIceWingFailed,"anti-ice failure state/effect missing")
 return true
end
return {Run=run}
