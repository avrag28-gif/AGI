-- FlightSim landing dynamics v0.1
-- Separates wheel contact, touchdown classification, braking and reverse thrust.
local LandingDynamics={}; LandingDynamics.__index=LandingDynamics
function LandingDynamics.new(state) return setmetatable({state=state,lastGround=true,touchdownTimer=0},LandingDynamics) end
function LandingDynamics:Step(dt)
 local x=self.state:Get(); local l=x.Landing; local gear=x.GearStatus or {}; local onGround=x.GroundContact==true
 local speed=math.max(x.Airspeed or 0,0); local sink=math.max(-(x.VerticalSpeed or 0),0); local gearDown=gear.DownLocked==true
 l.WheelContact=onGround and gearDown; l.TouchdownQuality="NONE"
 if onGround and not self.lastGround then
  l.Touchdown=true; self.touchdownTimer=0.5
  if sink<2 then l.TouchdownQuality="SMOOTH" elseif sink<4 then l.TouchdownQuality="FIRM" else l.TouchdownQuality="HARD" end
 end
 if self.touchdownTimer>0 then self.touchdownTimer=math.max(0,self.touchdownTimer-dt) end
 l.TouchdownEvent=self.touchdownTimer>0
 l.BrakingActive=onGround and speed>3 and ((x.Brakes and x.Brakes.BrakePressure or 0)>0)
 l.ReverseThrust=onGround and speed>20 and (x.ReverseThrust or 0)>0
 l.RolloutDistance=l.RolloutDistance or 0
 if onGround then l.RolloutDistance+=math.max(speed*0.514444,0)*dt else l.RolloutDistance=0 end
 if onGround and speed<5 then l.Phase="GROUND" elseif onGround then l.Phase="ROLLOUT" end
 self.lastGround=onGround
end
return LandingDynamics
