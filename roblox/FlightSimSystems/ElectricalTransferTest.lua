-- Electrical transfer-source regression test v0.1
local State=require(script.Parent.State)
local Electrical=require(script.Parent.Electrical)
local Test={}
local function check(c,m) if not c then error(m,2) end end
function Test.Run()
 local s=State.new(); local x=s:Get()
 x.Electrical.Battery=false
 x.Electrical.ExternalPower=false
 x.Electrical.Bus1=false; x.Electrical.Bus2=false
 x.Engines[1].GeneratorAvailable=true
 x.Engines[2].GeneratorAvailable=true
 x.Failures.Electrical.Bus1=true
 x.Failures.Electrical.Bus2=false
 Electrical.new(s):Step(0.1)
 local e=s:Get().Electrical; local es=s:Get().ElectricalState
 check(e.Bus1==true and e.Bus2==true,"healthy generator transfer did not keep both buses energized")
 check(es.Source1=="GEN2_TRANSFER","Bus1 transfer source telemetry is incorrect")
 check(es.Source2=="GEN2","Bus2 own-generator telemetry is incorrect")
 x=s:Get(); x.Failures.Electrical.Bus2=true; x.Failures.Electrical.Bus1=false
 Electrical.new(s):Step(0.1); es=s:Get().ElectricalState
 check(es.Source1=="GEN1","Bus1 own-generator telemetry is incorrect after transfer reversal")
 check(es.Source2=="GEN1_TRANSFER","Bus2 transfer source telemetry is incorrect")
 return true
end
return Test
