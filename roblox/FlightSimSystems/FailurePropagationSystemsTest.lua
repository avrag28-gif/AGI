-- FlightSim electrical/hydraulic failure propagation contract tests v0.2
-- Failures derives effects; the affected subsystem owns the physical-state response.
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local Electrical=require(script.Parent.Electrical)
local Hydraulic=require(script.Parent.Hydraulic)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Engines={[1]={Running=true,GeneratorAvailable=true},[2]={Running=true,GeneratorAvailable=true}},
  APU={Running=true,GeneratorAvailable=true},
  Electrical={Bus1=true,Bus2=true,APU=true,Battery=true,ExternalPower=false},
  BatteryCharge=1,
  Hydraulic={A=3000,B=3000},
  HydraulicDemand={FlightControls=0.2,LandingGear=0,Brakes=0},
  Failures={},
 })
 FailureSchema.Apply(s.data)
 local failures=Failures.new(s); local electrical=Electrical.new(s); local hydraulic=Hydraulic.new(s,{HydraulicMax=3000})
 s.data.Failures.Electrical.Bus1=true
 failures:Step(1); check(s.data.FailureEffects.ElectricalBus1Failed,"Bus1 failure effect missing"); electrical:Step(1)
 check(not s.data.Electrical.Bus1,"failed Bus1 must be isolated by Electrical"); check(s.data.Electrical.Bus2,"healthy Bus2 should remain powered")
 s.data.Failures.Hydraulic.A=true
 failures:Step(1); check(s.data.FailureEffects.HydraulicAFailed,"hydraulic A failure effect missing"); hydraulic:Step(1)
 check(s.data.Hydraulic.A==0,"failed hydraulic A must be driven to zero by Hydraulic"); check(s.data.Hydraulic.B>0,"healthy hydraulic B should retain pressure")
 return true
end
return {Run=run}
