-- Physics trim regression test v0.1
-- Ensures trim reaches aerodynamics exactly once through the elevator surface.
local State=require(script.Parent.State)
local Trim=require(script.Parent.Trim)
local FlightControls=require(script.Parent.FlightControls)
local Physics=require(script.Parent.Physics)
local function check(ok,msg) assert(ok,msg) end
local function base()
 local s=State.new()
 s.GroundContact=false
 s.Airspeed=180
 s.Altitude=10000
 s.Pitch=5
 s.PitchRate=0
 s.Roll=0
 s.Hydraulic.A.Pressure=3000
 s.Hydraulic.B.Pressure=3000
 s.Engines[1].Running=true
 s.Engines[2].Running=true
 s.Engines[1].Thrust=0
 s.Engines[2].Thrust=0
 s.Controls.Elevator=0
 return s
end
local function run()
 local neutral=base()
 FlightControls.new(neutral):Step(1/60)
 Physics.new(neutral):Step(1/60)
 local trimmed=base()
 trimmed.Controls.Trim=1
 Trim.new(trimmed):Step(0.4)
 FlightControls.new(trimmed):Step(1/60)
 local surfaceTrim=trimmed.Surface.Elevator
 check(surfaceTrim>0,"trim must reach the elevator surface")
 Physics.new(trimmed):Step(1/60)
 check(trimmed.AoA>neutral.AoA,"positive trim must increase AoA through elevator authority")
 check(trimmed.AoA-neutral.AoA<2.0,"trim must not receive a second direct AoA contribution")
 return true
end
return {Run=run}
