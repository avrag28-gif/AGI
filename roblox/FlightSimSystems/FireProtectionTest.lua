-- Fire protection test-switch regression v0.1
local State=require(script.Parent.State)
local FireProtection=require(script.Parent.FireProtection)
local Test={}
local function check(c,m) if not c then error(m,2) end end
function Test.Run()
 local s=State.new(); local x=s:Get()
 x.Engines[1].Running=true; x.Engines[1].FuelOn=true; x.Engines[1].Ignition=true; x.Engines[1].EGT=400
 x.Engines[2].Running=true; x.Engines[2].FuelOn=true; x.Engines[2].Ignition=true; x.Engines[2].EGT=400
 x.APU.Running=true; x.APU.RPM=95
 x.FireProtection.FireTest=true
 FireProtection.new(s):Step(0.1)
 x=s:Get()
 check(x.FireProtection.Engines[1].Warning and x.FireProtection.Engines[2].Warning and x.FireProtection.APU.Warning,"fire test did not generate warnings")
 check(x.FireProtection.Engines[1].Fire==false and x.FireProtection.Engines[2].Fire==false and x.FireProtection.APU.Fire==false,"fire test incorrectly latched actual fire")
 check(x.Engines[1].FuelOn==true and x.Engines[2].FuelOn==true,"fire test incorrectly shut down engine fuel")
 check(x.APU.Running==true,"fire test incorrectly shut down APU")
 return true
end
return Test
