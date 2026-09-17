-- FlightSim approach -> landing state integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local LandingModel=require(script.Parent.LandingModel)
local LandingDynamics=require(script.Parent.LandingDynamics)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Airspeed=135,Altitude=40,VerticalSpeed=-500,GroundContact=false,
  GearStatus={DownLocked=true},Brakes={BrakePressure=0},ReverseThrust=0,
  Landing={}
 })
 local model=LandingModel.new(s); local dynamics=LandingDynamics.new(s)
 model:Step(1/60); dynamics:Step(1/60)
 check(s.data.Landing.Phase=="AIRBORNE","initial airborne approach must not create a false flare")
 s.data.Altitude=35
 model:Step(1/60); dynamics:Step(1/60)
 check(s.data.Landing.Phase=="FLARE","low descending approach with gear down must enter flare")
 check(s.data.Landing.Flare==true,"flare flag must be asserted")
 s.data.Altitude=1.5
 s.data.VerticalSpeed=-300
 s.data.GroundContact=true
 model:Step(1/60); dynamics:Step(1/60)
 check(s.data.Landing.Phase=="ROLLOUT","ground contact must transition to rollout")
 check(s.data.Landing.Touchdown==true,"ground transition must emit touchdown")
 check(s.data.Landing.WheelContact==true,"locked gear on ground must create wheel contact")
 check(s.data.Landing.TouchdownQuality=="FIRM","300 fpm sink should classify as firm touchdown")
 s.data.Airspeed=80; s.data.Brakes.BrakePressure=.6; s.data.ReverseThrust=.5
 dynamics:Step(1)
 check(s.data.Landing.BrakingActive==true,"braking must be active during rollout")
 check(s.data.Landing.ReverseThrust==true,"reverse thrust must be active during rollout")
 check(s.data.Landing.RolloutDistance>0,"rollout distance must accumulate on ground")
 return true
end
return {Run=run}
