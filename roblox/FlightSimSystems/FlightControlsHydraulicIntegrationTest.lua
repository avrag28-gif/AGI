-- FlightSim flight-control / hydraulic authority regression tests v0.1
local State=require(script.Parent.State)
local FlightControls=require(script.Parent.FlightControls)
local function check(ok,msg) assert(ok,msg) end
local function baseState()
 local s=State.new()
 s.GroundContact=false
 s.Airspeed=180
 s.Hydraulic.A.Pressure=3000
 s.Hydraulic.B.Pressure=3000
 s.Hydraulic.Standby.Pressure=0
 s.Controls.Aileron=1
 s.Controls.Elevator=1
 s.Controls.Rudder=1
 return s
end
local function run()
 -- Healthy primary hydraulics must provide full control-surface authority at speed.
 local healthy=baseState()
 FlightControls.new(healthy):Step(1/60)
 check(healthy.Surface.Aileron>0.8,"healthy A hydraulic authority should drive aileron near commanded deflection")
 check(healthy.Surface.Elevator>0.8,"healthy B hydraulic authority should drive elevator near commanded deflection")
 check(healthy.Surface.Rudder>0.8,"healthy primary hydraulics should drive rudder near commanded deflection")
 check(healthy.FlightControls.PrimaryHydraulicA==true and healthy.FlightControls.PrimaryHydraulicB==true,"primary hydraulic status should be exposed to flight controls")

 -- Losing A while B remains healthy must not remove all aileron/elevator authority,
 -- because this simulation allocates primary control groups across the two systems.
 local bOnly=baseState()
 bOnly.Hydraulic.A.Pressure=0
 FlightControls.new(bOnly):Step(1/60)
 check(bOnly.Surface.Aileron>0.8,"B-only condition should retain aileron authority")
 check(bOnly.Surface.Elevator>0.8,"B-only condition should retain elevator authority")

 -- Standby pressure is deliberately not a universal replacement for primary aileron/elevator authority.
 local standbyOnly=baseState()
 standbyOnly.Hydraulic.A.Pressure=0
 standbyOnly.Hydraulic.B.Pressure=0
 standbyOnly.Hydraulic.Standby.Pressure=3000
 FlightControls.new(standbyOnly):Step(1/60)
 check(standbyOnly.Surface.Aileron<0.2,"standby must not restore full aileron authority")
 check(standbyOnly.Surface.Elevator<0.2,"standby must not restore full elevator authority")
 check(standbyOnly.Surface.Rudder>0.1,"standby may retain limited rudder authority")

 -- Yaw damper feedback must react to sideslip/yaw-rate error without replacing pilot input.
 local damper=baseState()
 damper.Controls.Rudder=0
 damper.Controls.YawDamper=true
 damper.Sideslip=5
 damper.YawRate=2
 FlightControls.new(damper):Step(1/60)
 check(damper.Surface.Rudder<0,"yaw damper should command corrective rudder for positive beta/yaw rate")
 check(damper.ControlFeel.YawDamperActive==true,"yaw-damper status should be exposed")
 return true
end
return {Run=run}
