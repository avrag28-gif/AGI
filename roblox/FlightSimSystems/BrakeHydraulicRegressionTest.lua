-- Regression test: brake demand must remain present when hydraulic pressure is low.
local State=require(script.Parent.State)
local Brakes=require(script.Parent.Brakes)
local Test={}
local function check(condition,message)
 if not condition then error(message,2) end
end
function Test.Run()
 local state=State.new()
 state.Hydraulic.A.Pressure=0
 state.Hydraulic.B.Pressure=0
 state.Brakes.ToeBrake=1
 state.Brakes.Parking=false
 local brakes=Brakes.new(state)
 brakes:Step(0.1)
 check(state.Brakes.BrakePressure==0,"brake pressure should remain zero without hydraulic pressure")
 check(state.Brakes.HydraulicAvailable==false,"brakes incorrectly reported hydraulic availability")
 check(state.HydraulicDemand.Brakes==1,"brake hydraulic demand collapsed when pressure was unavailable")
 state.Hydraulic.A.Pressure=1800
 brakes:Step(0.1)
 check(state.Brakes.BrakePressure>0,"brakes did not respond after hydraulic pressure was restored")
 check(state.HydraulicDemand.Brakes==1,"brake demand changed despite unchanged pilot command")
 return true
end
return Test
