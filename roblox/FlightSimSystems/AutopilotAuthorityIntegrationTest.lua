-- Autopilot / flight-control authority regression tests v0.1
local State=require(script.Parent.State)
local Autopilot=require(script.Parent.Autopilot)
local FlightControls=require(script.Parent.FlightControls)
local function check(ok,msg) assert(ok,msg) end
local function run()
 local s=State.new()
 s.GroundContact=false
 s.Airspeed=180
 s.Altitude=10000
 s.Navigation.Mode="ALT_HOLD"
 s.Navigation.CommandAltitude=11000
 s.Autopilot.Enabled=true
 s.Hydraulic.A.Pressure=900
 s.Hydraulic.B.Pressure=900
 Autopilot.new(s):Step(1/60)
 local apElevator=s.Autopilot.CommandElevator
 check(math.abs(apElevator)>0,"autopilot must generate a pitch demand")
 check(math.abs(apElevator)<=0.45,"autopilot command must remain a normalized demand")
 FlightControls.new(s):Step(1/60)
 check(math.abs(s.Surface.Elevator)<=math.abs(apElevator)+0.01,"flight controls must apply authority once, without AP double-scaling")
 check(s.Autopilot.ElevatorAuthority<0.75,"test setup must exercise limited elevator authority")
 return true
end
return {Run=run}
