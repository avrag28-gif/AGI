-- FlightSim bleed-air deterministic contract tests v0.2
local BleedAir=require(script.Parent.BleedAir)
local function check(v,m) assert(v,m) end
local function run()
 local x={Engines={[1]={Running=true,N2=60},[2]={Running=true,N2=50}},APU={Running=false,GeneratorAvailable=false,RPM=0},Electrical={Bus1=true,Bus2=true},Failures={Engines={[1]={Active=false},[2]={Active=false}},Pressurization={Pack1=false,Pack2=false}},Pressurization={}}
 local state={Get=function() return x end}; local b=BleedAir.new(state)
 b:Step(1); check(x.BleedAir.Pack1Available and x.BleedAir.Pack2Available,"engine bleed should feed both packs"); check(x.BleedAir.Pack1Output>x.BleedAir.Pack2Output,"pack output should follow each engine N2")
 x.Failures.Engines[1].Active=true; b:Step(1); check(not x.BleedAir.Engine1Source,"failed engine must lose bleed source"); check(x.BleedAir.Pack2Available,"remaining engine must retain pack")
 x.Failures.Engines[2].Active=true; b:Step(1); check(not x.BleedAir.SourceAvailable,"both failed engines should remove source")
 x.Failures.Engines[1].Active=false; x.APU.Running=true; x.APU.GeneratorAvailable=true; x.APU.RPM=95; b:Step(1); check(x.BleedAir.APUSource,"available APU should provide bleed source"); check(x.BleedAir.Pack1Output>0 and x.BleedAir.Pack2Output>0,"APU bleed should supply both packs"); check(x.BleedAir.Pack1Output==x.BleedAir.Pack2Output,"APU-only pack outputs should match")
 x.Failures.Pressurization.Pack1=true; b:Step(1); check(not x.BleedAir.Pack1Available and x.BleedAir.Pack2Available,"pack failure should isolate only affected pack")
 return true
end
return {Run=run}
