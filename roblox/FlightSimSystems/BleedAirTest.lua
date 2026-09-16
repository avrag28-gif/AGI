-- FlightSim bleed-air deterministic contract tests v0.1
local BleedAir=require(script.Parent.BleedAir)
local function check(v,m) assert(v,m) end
local function run()
 local x={Engines={[1]={Running=true,N1=70,N2=60},[2]={Running=true,N1=70,N2=60}},APU={Running=false,GeneratorAvailable=false},Electrical={Bus1=true,Bus2=true},Failures={Engines={[1]={Active=false},[2]={Active=false}},Pressurization={Pack1=false,Pack2=false}},Pressurization={}}
 local state={Get=function() return x end}; local b=BleedAir.new(state); b:Step(1); check(x.BleedAir.Pack1Available and x.BleedAir.Pack2Available,"engine bleed should feed both packs"); check(x.BleedAir.TotalAirflow>0,"pack airflow expected")
 x.Failures.Engines[1].Active=true; b:Step(1); check(not x.BleedAir.Engine1Source,"failed engine must lose bleed source"); check(x.BleedAir.Pack2Available,"remaining engine must retain pack")
 x.Failures.Engines[2].Active=true; b:Step(1); check(not x.BleedAir.SourceAvailable,"both failed engines should remove source")
 return true
end
return {Run=run}
