-- FlightSim complete failure-domain integration contract tests v0.1
-- These tests verify ownership boundaries and physical responses for every current failure domain.
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local Engine=require(script.Parent.Engine)
local Electrical=require(script.Parent.Electrical)
local Hydraulic=require(script.Parent.Hydraulic)
local FlightControls=require(script.Parent.FlightControls)
local FireProtection=require(script.Parent.FireProtection)
local APU=require(script.Parent.APU)
local BleedAir=require(script.Parent.BleedAir)
local Pressurization=require(script.Parent.Pressurization)
local AntiIce=require(script.Parent.AntiIce)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Altitude=12000,Airspeed=140,GroundContact=false,Throttle={[1]=0,[2]=0},Engines={[1]={Running=true,N1=70,N2=60,EGT=600,OilPressure=50,FuelOn=true,Ignition=true,Starter=false,Thrust=50000,GeneratorAvailable=true},[2]={Running=true,N1=70,N2=60,EGT=600,OilPressure=50,FuelOn=true,Ignition=true,Starter=false,Thrust=50000,GeneratorAvailable=true}},APU={Running=true,Starter=false,EGT=300,RPM=95,GeneratorAvailable=true},Electrical={Bus1=true,Bus2=true,APU=true,Battery=true,ExternalPower=false},BatteryCharge=1,Hydraulic={A=3000,B=3000},HydraulicDemand={FlightControls=0.2,LandingGear=0,Brakes=0},Controls={Aileron=0.4,Elevator=0.2,Rudder=0.1,Flap=0},Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},Fuel={Total=30000},FuelSystem={EngineFuelAvailable={[1]=true,[2]=true}},Environment={Icing=0.8},WeatherEffects={IcingDragFactor=1,IcingLiftFactor=1},BleedAir={},Pressurization={Auto=false,ManualCommand=0.35,OutflowValve=0.35},AntiIce={EnginePenalty={[1]=1,[2]=1}},FireProtection={Engines={[1]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true},[2]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true}},APU={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true},FireTest=false}}
end
local function run()
 local s=state(base()); FailureSchema.Apply(s.data); local f=Failures.new(s)
 local engine=Engine.new(s); local electrical=Electrical.new(s); local hydraulic=Hydraulic.new(s,{HydraulicMax=3000}); local controls=FlightControls.new(s); local fire=FireProtection.new(s); local apu=APU.new(s); local bleed=BleedAir.new(s); local press=Pressurization.new(s); local ice=AntiIce.new(s)
 f:SetEngine(1,true,"TEST_ENGINE"); f:Step(1); check(s.data.Engines[1].Running,"Failures must not mutate engine physics"); engine:Step(1); check(not s.data.Engines[1].Running and s.data.Engines[1].Thrust==0,"Engine failure response missing")
 f:SetElectrical("Bus1",true); f:Step(1); electrical:Step(1); check(not s.data.Electrical.Bus1 and s.data.Electrical.Bus2,"Electrical failure response missing")
 f:SetHydraulic("A",true); f:Step(1); hydraulic:Step(1); check(s.data.Hydraulic.A==0 and s.data.Hydraulic.B>0,"Hydraulic failure response missing")
 f:SetFlightControl("Aileron",true); f:Step(1); controls:Step(1); check(math.abs(s.data.Surface.Aileron)<1e-6,"Flight-control failure response missing")
 f:SetEngineFire(2,true); f:Step(1); fire:Step(1); check(s.data.FireProtection.Engines[2].Fire and not s.data.Engines[2].FuelOn,"engine fire response missing")
 f:SetElectrical("APU",true); f:Step(1); apu:Step(1); check(not s.data.APU.GeneratorAvailable,"APU generator failure response missing")
 s.data.Failures.Engines[1].Active=false; f:SetPressurization("Pack1",true); f:Step(1); s.data.Engines[1].Running=true; s.data.Electrical.Bus1=true; bleed:Step(1); check(not s.data.BleedAir.Pack1Available and s.data.BleedAir.Pack2Available,"pack failure response missing")
 f:SetPressurization("OutflowValve",true); f:Step(1); press:SetMode(false); press:SetOutflow(0.2); press:Step(1); check(math.abs(s.data.Pressurization.OutflowValve-0.35)<1e-6,"outflow valve failure must prevent command movement")
 f:SetAntiIce("Engine1",true); f:Step(1); ice:SetEngine(1,true); ice:Step(1); check(not s.data.AntiIce.Engine1 and s.data.AntiIce.Warning,"anti-ice failure response missing")
 return true
end
return {Run=run}
