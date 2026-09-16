-- FlightSim landing dynamics v0.2
-- LandingDynamics is the canonical owner of wheel contact, touchdown event and quality.
local LandingDynamics={}; LandingDynamics.__index=LandingDynamics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingDynamics.new(state) return setmetatable({state=state,lastGround=true,touchdownTimer=0,touchdownQuality="NONE"},LandingDynamics) end
function LandingDynamics:Step(dt)
 local x=self.state:Get(); local l=x.Landing; local gear=x.GearStatus or {}; local onGround=x.GroundContact==true
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local sink=math.max(-(tonumber(x.VerticalSpeed) or 0),0); local gearDown=gear.DownLocked==true
 local d=math.max(0,dt)
 l.WheelContact=onGround and gearDown
 l.Touchdown=false
 if onGround and not self.lastGround then
  l.Touchdown=true; self.touchdownTimer=1.0
  if sink<2 then self.touchdownQuality="SMOOTH" elseif sink<4 then self.touchdownQuality="FIRM" else self.touchdownQuality="HARD" end
 end
 self.touchdownTimer=math.max(0,self.touchdownTimer-d)
 l.TouchdownEvent=self.touchdownTimer>0
 l.TouchdownQuality=self.touchdownQuality
 l.BrakingActive=onGround and speed>3 and ((x.Brakes and tonumber(x.Brakes.BrakePressure) or 0)>0)
 l.ReverseThrust=onGround and speed>20 and (tonumber(x.ReverseThrust) or 0)>0
 if onGround then
  l.RolloutDistance=(tonumber(l.RolloutDistance) or 0)+math.max(speed*0.514444,0)*d
  if speed<5 then l.Phase="GROUND"; l.Rollout=false else l.Phase="ROLLOUT"; l.Rollout=true end
 else
  l.RolloutDistance=0; l.Rollout=false
 end
 self.lastGround=onGround
end
return LandingDynamics
