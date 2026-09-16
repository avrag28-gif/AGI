-- FlightSim nose-wheel steering / taxi dynamics v0.2
-- Server-authoritative ground directional-control foundation.
-- Values are simulation approximations, not certified aircraft data.
local GroundSteering={}; GroundSteering.__index=GroundSteering
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
function GroundSteering.new(state) return setmetatable({state=state},GroundSteering) end
function GroundSteering:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local g=x.GearStatus or {}; local h=x.Hydraulic or {}; local gs=x.GroundSteering or {}
 local speed=math.max(x.Airspeed or 0,0)
 local hydraulic=math.max(h.A or 0,h.B or 0)
 local ground=x.GroundContact==true
 local gearReady=g.DownLocked==true and (tonumber(g.Nose) or 0)>=0.98
 local available=ground and gearReady and hydraulic>=900
 local command=clamp(tonumber(c.NoseWheelSteering) or 0,-1,1)
 local maxAngle=clamp(12*(0.35+0.65*clamp((25-speed)/25,0,1)),4,12)
 local targetAngle=command*maxAngle
 local angle=approach(tonumber(gs.NoseWheelAngle) or 0,available and targetAngle or 0,24,dt)
 local lowSpeedAuthority=clamp((speed-1)/18,0,1)
 local highSpeedFade=1-clamp((speed-35)/45,0,1)
 local steeringAuthority=lowSpeedAuthority*highSpeedFade
 local noseYaw=0
 if available and speed>1 then
  noseYaw=clamp((angle/maxAngle)*28*steeringAuthority,-18,18)
 end
 local left=(x.Brakes and x.Brakes.LeftPressure) or 0
 local right=(x.Brakes and x.Brakes.RightPressure) or 0
 local differential=0
 if available and speed>2 and speed<22 then
  differential=clamp((right-left)*8,-8,8)
 end
 local rudder=clamp(tonumber(c.Rudder) or 0,-1,1)
 local rudderAuthority=clamp((speed-28)/32,0,1)
 local rudderYaw=ground and rudder*9*rudderAuthority or 0
 local yawRate=clamp(noseYaw+differential+rudderYaw,-18,18)
 gs.Available=available
 gs.Command=command
 gs.NoseWheelAngle=angle
 gs.MaxAngle=maxAngle
 gs.YawRate=yawRate
 gs.NoseYawRate=noseYaw
 gs.RudderYawRate=rudderYaw
 gs.SpeedAuthority=steeringAuthority
 gs.DifferentialBrakeAssist=differential
 gs.TakeoffRudderBlend=rudderAuthority
 x.GroundSteering=gs
end
return GroundSteering
