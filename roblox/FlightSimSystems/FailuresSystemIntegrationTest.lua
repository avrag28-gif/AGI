-- FlightSim failure-system integration contract tests v0.1
-- Covers every currently modeled failure domain without requiring Roblox runtime execution.
local FailureSchema=require(script.Parent.FailureSchema)
local Failures=require(script.Parent.Failures)
local Engine=require(script.Parent.Engine)
local Electrical=require(script.Parent.Electrical)
local Hydraulic=require(script.Parent.Hydraulic)
local FlightControls=require(script.Parent.FlightControls)
local BleedAir=require(script.Parent.BleedAir)
local Pressurization=require(script.Parent.Pressurization)
local AntiIce=require(script.Parent.AntiIce)
local FireProtection=require(script.Parent.FireProtection)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Altitude=12000,Airspeed=160,GroundContact=false,Throttle={[1]=0.5,[2]=0.5},
  Engines={[1]={Running=true,N2=65,N1=60,EGT=500,OilPressure=40,FuelOn=true,Ignition=true,Starter=false,Thrust=30000,GeneratorAvailable=true},[2]={Running=true,N2=65,N1=60,EGT=500,OilPressure=40,FuelOn=true,Ignition=true,Starter=false,Thrust=30000,GeneratorAvailable=true}},
  APU={Running=true,RPM=95,GeneratorAvailable=true,EGT=250},
  Electrical={Bus1=true,Bus2=true,APU=true,Battery=true,ExternalPower=false},BatteryCharge=1,
  Hydraulic={A=3000,B=3000},HydraulicDemand={FlightControls=0.2,LandingGear=0,Brakes=0},
  Controls={Aileron=0.5,Elevator=0.2,Rudder=0.1,Flap=0},Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0},
  BleedAir={},Pressurization={},AntiIce={},Environment={Icing=0.8},WeatherEffects={IcingDragFactor=1,IcingLiftFactor=1},
  FireProtection={},Failures={}
 })
 FailureSchema.Apply(s.data)
 local failures=Failures.new(s); local engine=Engine.new(s); local electrical=Electrical.new(s); local hydraulic=Hydraulic.new(s,{HydraulicMax=3000}); local controls=FlightControls.new(s); local bleed=BleedAir.new(s); local press=Pressurization.new(s); local ice=AntiIce.new(s); local fire=FireProtection.new(s)
 -- Engine fault: state is declared by Failures, physical shutdown is owned by Engine.
 check(failures:SetEngine(1,true,"TEST_ENGINE"),"engine setter failed"); failures:Step(1); check(s.data.FailureEffects.Engine1Failed,"engine effect missing"); check(s.data.Engines[1].Running,"Failures must not mutate engine state"); engine:Step(1); check(not s.data.Engines[1].Running and s.data.Engines[1].Thrust==0,"Engine did not apply engine failure")
 -- Electrical fault: failed bus is isolated by Electrical, healthy bus remains usable.
 check(failures:SetElectrical("Bus1",true),"Bus1 setter failed"); failures:Step(1); electrical:Step(1); check(not s.data.Electrical.Bus1,"Bus1 failure not isolated"); check(s.data.Electrical.Bus2,"Bus2 should remain available")
 -- Hydraulic fault: failed side loses pressure, healthy side remains physical source.
 check(failures:SetHydraulic("A",true),"Hydraulic A setter failed"); failures:Step(1); hydraulic:Step(1); check(s.data.Hydraulic.A==0,"Hydraulic A failure not applied"); check(s.data.Hydraulic.B>0,"Hydraulic B should remain pressurized")
 -- Flight-control fault: authority is derived, then consumed by FlightControls.
 check(failures:SetFlightControl("Aileron",true),"Aileron setter failed"); failures:Step(1); controls:Step(1); check(s.data.FailureEffects.AileronAuthority==0,"Aileron authority effect missing"); check(math.abs(s.data.Surface.Aileron)<0.001,"Aileron failure did not remove surface command")
 -- Pressurization pack fault and anti-ice component fault are consumed by their own systems.
 check(failures:SetPressurization("Pack1",true),"Pack1 setter failed"); check(failures:SetAntiIce("Engine2",true),"Engine2 anti-ice setter failed"); failures:Step(1); bleed:Step(1); press:Step(1); ice:SetEngine(2,true); ice:Step(1); check(not s.data.Pressurization.Pack1Available,"failed pack must be unavailable"); check(not s.data.AntiIce.Engine2 and s.data.AntiIce.Warning,"failed anti-ice component must disengage and warn")
 -- Fire fault: FireProtection owns the immediate fire-protection response.
 check(failures:SetEngineFire(2,true),"engine fire setter failed"); failures:Step(1); fire:Step(1); check(s.data.FireProtection.Engines[2].Fire,"engine fire must be annunciated"); check(not s.data.Engines[2].FuelOn and not s.data.Engines[2].Ignition,"fire protection must shut off engine fuel/ignition")
 -- Clearing a fault must not leave stale derived failure effects.
 check(failures:SetEngine(1,false),"engine clear failed"); check(failures:SetElectrical("Bus1",false),"Bus1 clear failed"); check(failures:SetHydraulic("A",false),"Hydraulic A clear failed"); check(failures:SetFlightControl("Aileron",false),"Aileron clear failed"); check(failures:SetPressurization("Pack1",false),"Pack1 clear failed"); check(failures:SetAntiIce("Engine2",false),"anti-ice clear failed"); failures:Step(1); check(not s.data.FailureEffects.Engine1Failed and not s.data.FailureEffects.ElectricalBus1Failed and not s.data.FailureEffects.HydraulicAFailed and s.data.FailureEffects.AileronAuthority==1 and not s.data.FailureEffects.Pack1Failed and not s.data.FailureEffects.AntiIceEngine2Failed,"cleared failure effects are stale")
 return true
end
return {Run=run}
