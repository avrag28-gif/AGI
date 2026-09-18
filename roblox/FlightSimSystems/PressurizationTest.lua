-- FlightSim pressurization deterministic contract tests v0.2
local Pressurization=require(script.Parent.Pressurization)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Altitude=0,
  Electrical={Bus1=false,Bus2=false},
  Engines={[1]={Running=false},[2]={Running=false}},
  APU={Running=false,RPM=0},
  BleedAir={Pack1Available=false,Pack2Available=false,Engine1Source=false,Engine2Source=false,APUSource=false,SourceAvailable=false,TotalAirflow=0},
  Failures={Engines={[1]={Active=false},[2]={Active=false}},Pressurization={}},
 })
 local p=Pressurization.new(s); p:Step(1)
 check(not s.data.Pressurization.SourceAvailable,"cold aircraft must have no pressurization source")
 s.data.Engines[1].Running=true; s.data.Engines[1].N2=60
 s.data.Electrical.Bus1=true
 s.data.BleedAir.Engine1Source=true
 s.data.BleedAir.Pack1Available=true
 s.data.BleedAir.SourceAvailable=true
 s.data.BleedAir.TotalAirflow=1
 s.data.Altitude=12000
 p:Step(60)
 check(s.data.Pressurization.Pack1Available,"running engine should provide pack source")
 check(s.data.Pressurization.CabinAltitudeFt>0,"cabin altitude should respond")
 p:SetMode(false); p:SetOutflow(0); p:Step(10)
 check(s.data.Pressurization.OutflowValve==0,"manual outflow command not applied")
 p:SetLandingAltitude(500)
 check(s.data.Pressurization.LandingAltitudeFt==500,"landing altitude setter failed")
 s.data.Failures.Engines[1].Active=true
 s.data.BleedAir.Engine1Source=false
 s.data.BleedAir.Pack1Available=false
 s.data.BleedAir.SourceAvailable=false
 p:Step(1)
 check(not s.data.Pressurization.Pack1Available,"failed engine must remove its bleed source")
 s.data.APU.Running=true; s.data.APU.RPM=95; s.data.Electrical.Bus2=true
 s.data.BleedAir.APUSource=true; s.data.BleedAir.Pack1Available=true; s.data.BleedAir.SourceAvailable=true
 p:Step(1)
 check(s.data.Pressurization.SourceAvailable,"APU bleed source should restore pressurization source")
 return true
end
return {Run=run}
