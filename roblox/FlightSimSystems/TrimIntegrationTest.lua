-- Trim / flight-control integration regression tests v0.1
local State=require(script.Parent.State)
local Trim=require(script.Parent.Trim)
local FlightControls=require(script.Parent.FlightControls)
local function check(ok,msg) assert(ok,msg) end
local function run()
 local s=State.new()
 s.GroundContact=false
 s.Airspeed=180
 s.Hydraulic.A.Pressure=3000
 s.Hydraulic.B.Pressure=3000
 s.Controls.Elevator=0
 s.Controls.Trim=1
 Trim.new(s):Step(0.2)
 check(s.TrimPitch>0,"pilot trim command must move authoritative trim state")
 check(math.abs(s.TrimState.Pitch-s.TrimPitch)<1e-9,"trim state pitch must mirror authoritative trim")
 local before=s.Surface.Elevator
 FlightControls.new(s):Step(1/60)
 check(s.Surface.Elevator>before,"positive trim must contribute to elevator command")
 local held=s.TrimPitch
 s.Autopilot.Enabled=true
 s.Controls.Trim=0
 Trim.new(s):Step(0.2)
 check(math.abs(s.TrimPitch-held)<1e-9,"autopilot must not move trim when there is no pilot trim command")
 local low=State.new()
 low.GroundContact=false
 low.Airspeed=180
 low.Hydraulic.A.Pressure=0
 low.Hydraulic.B.Pressure=0
 low.Hydraulic.Standby.Pressure=3000
 low.Controls.Elevator=1
 FlightControls.new(low):Step(1/60)
 check(math.abs(low.Surface.Elevator)<=0.13,"standby hydraulic must not restore primary elevator authority")
 return true
end
return {Run=run}
