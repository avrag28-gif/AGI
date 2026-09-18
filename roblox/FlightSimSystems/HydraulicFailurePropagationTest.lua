-- Hydraulic failure propagation regression tests v0.1
local State=require(script.Parent.State)
local GroundSteering=require(script.Parent.GroundSteering)
local Brakes=require(script.Parent.Brakes)
local LandingGear=require(script.Parent.LandingGear)
local Test={}
local function check(c,m) if not c then error(m,2) end end

local function base()
 local s=State.new()
 local x=s:Get()
 x.GroundContact=true
 x.Airspeed=10
 x.Hydraulic.A.Pressure=3000
 x.Hydraulic.B.Pressure=3000
 x.Hydraulic.Standby.Pressure=3000
 x.GearStatus={Nose=1,Left=1,Right=1,DownLocked=true,UpLocked=false,Transitioning=false,Unsafe=false}
 x.Gear={Nose=true,Left=true,Right=true}
 x.Controls.NoseWheelSteering=1
 x.Brakes.ToeBrake=1
 x.FailureEffects={}
 return s
end

function Test.Run()
 local s=base()
 GroundSteering.new(s):Step(0.1)
 check(s:Get().GroundSteering.Available==true,"healthy hydraulic steering unavailable")
 s:Get().FailureEffects.HydraulicAFailed=true
 s:Get().FailureEffects.HydraulicBFailed=true
 GroundSteering.new(s):Step(0.1)
 check(s:Get().GroundSteering.Available==false,"ground steering ignored failed primary hydraulics")

 s=base()
 Brakes.new(s):Step(0.1)
 check(s:Get().Brakes.HydraulicAvailable==true,"healthy hydraulic brakes unavailable")
 s:Get().FailureEffects.HydraulicAFailed=true
 s:Get().FailureEffects.HydraulicBFailed=true
 Brakes.new(s):Step(0.1)
 check(s:Get().Brakes.HydraulicAvailable==false,"brakes ignored failed primary hydraulics")
 check(s:Get().Brakes.LeftPressure<0.1 and s:Get().Brakes.RightPressure<0.1,"brake pressure persisted after total hydraulic failure")

 s=base()
 s:Get().Gear.Nose=false
 LandingGear.new(s):Step(0.1)
 check(s:Get().GearStatus.HydraulicAvailable==true,"healthy hydraulic gear unavailable")
 s:Get().FailureEffects.HydraulicAFailed=true
 s:Get().FailureEffects.HydraulicBFailed=true
 LandingGear.new(s):Step(0.1)
 check(s:Get().GearStatus.HydraulicAvailable==false,"landing gear ignored failed primary hydraulics")
 return true
end
return Test
