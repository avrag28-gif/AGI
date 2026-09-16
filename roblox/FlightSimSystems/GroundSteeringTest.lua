-- FlightSim ground steering contract tests v0.1
-- Source-level tests; Roblox runtime execution is still required for physical asset behavior.
local GroundSteering=require(script.Parent.GroundSteering)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Airspeed=10,GroundContact=true,Controls={NoseWheelSteering=0,Rudder=0},GearStatus={DownLocked=true,Nose=1},Hydraulic={A=1800,B=1800},Brakes={LeftPressure=0,RightPressure=0},GroundSteering={}}
end
local function run()
 local s=state(base()); local g=GroundSteering.new(s)
 g:Step(1/60); check(s.data.GroundSteering.Available,"ground steering must be available with locked nose gear and hydraulic pressure")
 s.data.Controls.NoseWheelSteering=1; for _=1,30 do g:Step(1/60) end
 check(s.data.GroundSteering.NoseWheelAngle>0,"positive steering command must move nose wheel right/positive")
 check(s.data.GroundSteering.YawRate>0,"positive nose-wheel angle must produce positive ground yaw")
 s.data.Controls.NoseWheelSteering=0; s.data.Brakes.LeftPressure=1; s.data.Brakes.RightPressure=0; g:Step(1/60); check(s.data.GroundSteering.DifferentialBrakeAssist<0,"left-heavy braking must produce negative differential yaw")
 s.data.Controls.NoseWheelSteering=1; s.data.Hydraulic.A=0; s.data.Hydraulic.B=0; for _=1,30 do g:Step(1/60) end
 check(s.data.GroundSteering.NoseWheelAngle==0 and s.data.GroundSteering.YawRate==0,"loss of hydraulic pressure must center and disable nose-wheel steering")
 s.data.Hydraulic.A=1800; s.data.GearStatus.DownLocked=false; g:Step(1/60); check(not s.data.GroundSteering.Available,"unlocked gear must disable nose-wheel steering")
 return true
end
return {Run=run}
