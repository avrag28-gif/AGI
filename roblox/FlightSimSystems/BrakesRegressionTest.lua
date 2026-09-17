-- Brake regression tests v0.1
-- Covers pressure independence of demand, autobrake activation, wheel-slip protection and thermal response.
local State=require(script.Parent.State)
local Brakes=require(script.Parent.Brakes)
local Test={}
local function check(condition,message)
 if not condition then error(message,2) end
end
function Test.Run()
 local state=State.new()
 state.Hydraulic.A.Pressure=1800
 state.Hydraulic.B.Pressure=1800
 state.GroundContact=true
 state.GearStatus.DownLocked=true
 state.Brakes.Parking=false
 state.Brakes.ToeBrake=0
 state.Brakes.AutobrakeArmed=true
 state.Brakes.AutobrakeMode="2"
 state.Airspeed=100
 local brakes=Brakes.new(state)
 brakes:Step(0.1)
 check(state.Brakes.AutobrakeActive==true,"armed autobrake did not activate on wheel contact")
 check(state.Brakes.BrakeDemand>0,"autobrake did not create braking demand")
 check(state.Brakes.BrakePressure>0,"autobrake did not produce brake pressure")
 check(state.Brakes.AntiSkidActive==false,"anti-skid activated without wheel-speed slip data")
 local beforeTemp=state.Brakes.BrakeTemperatureLeft
 brakes:Step(1)
 check(state.Brakes.BrakeTemperatureLeft>beforeTemp,"brake temperature did not rise under braking")
 state.Brakes.LeftWheelSpeed=50
 state.Brakes.RightWheelSpeed=50
 brakes:Step(0.1)
 check(state.Brakes.AntiSkidActive==true,"anti-skid did not react to wheel-speed slip")
 check(state.Brakes.LeftPressure<state.Brakes.BrakePressure,"anti-skid did not reduce wheel pressure")
 state.Brakes.AutobrakeArmed=false
 state.Brakes.ToeBrake=1
 state.Hydraulic.A.Pressure=0
 state.Hydraulic.B.Pressure=0
 brakes:Step(0.1)
 check(state.HydraulicDemand.Brakes==1,"manual brake demand disappeared with hydraulic failure")
 check(state.Brakes.BrakePressure<1,"failed hydraulics incorrectly produced full brake pressure")
 return true
end
return Test
