-- Landing gear hydraulic regression tests v0.2
local State=require(script.Parent.State)
local LandingGear=require(script.Parent.LandingGear)
local Test={}
local function check(condition,message) if not condition then error(message,2) end end
function Test.Run()
 local state=State.new()
 local gear=LandingGear.new(state)
 state.Gear.Nose=false; state.Gear.Left=false; state.Gear.Right=false
 state.GearPosition={Nose=1,Left=1,Right=1}
 state.Hydraulic.A.Pressure=0; state.Hydraulic.B.Pressure=0; state.Hydraulic.Standby.Pressure=3000
 gear:Step(0.1)
 check(state.GearPosition.Nose==1,"gear moved without primary hydraulic pressure")
 check(state.HydraulicDemand.LandingGear==0,"gear demand was reported while already stationary")
 check(state.GearStatus.AlternateExtension==false,"alternate extension was silently enabled")
 state.Gear.Nose=true; state.Gear.Left=true; state.Gear.Right=true
 state.GearPosition={Nose=0,Left=0,Right=0}
 state.Hydraulic.A.Pressure=0; state.Hydraulic.B.Pressure=0
 gear:Step(0.1)
 check(state.HydraulicDemand.LandingGear>0,"gear extension did not report actuator demand")
 check(state.GearPosition.Nose==0,"gear moved without primary hydraulic pressure")
 state.Hydraulic.A.Pressure=1500; state.Hydraulic.B.Pressure=1500
 gear:Step(0.1)
 check(state.GearPosition.Nose>0,"gear did not move with primary hydraulic pressure")
 return true
end
return Test
