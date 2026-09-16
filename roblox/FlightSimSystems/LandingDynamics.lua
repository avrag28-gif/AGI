-- FlightSim landing dynamics v0.3
-- LandingDynamics is the canonical owner of wheel contact, touchdown event and touchdown quality.
-- Units: Airspeed=kt, VerticalSpeed=ft/min, RolloutDistance=m.
local LandingDynamics={}; LandingDynamics.__index=LandingDynamics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingDynamics.new(state) return setmetatable({state=state,lastGround=nil,touchdownTimer=0,touchdownQuality="NONE",initialized=false},LandingDynamics) end
function LandingDynamics:Step(dt)
 local x=self.state:Get(); local l=x.Landing or {}; local gear=x.GearStatus or {}; local onGround=x.GroundContact==true
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local verticalSpeed=tonumber(x.VerticalSpeed) or 0; local sinkFtMin=math.max(-verticalSpeed,0); local gearDown=gear.DownLocked==true
 local d=math.max(tonumber(dt) or 0,0)
 if not self.initialized then self.lastGround=onGround; self.initialized=true end
 l.WheelContact=onGround and gearDown
 l.Touchdown=false
 if onGround and self.lastGround==false then
  l.Touchdown=true; self.touchdownTimer=1.0
  if sinkFtMin<120 then self.touchdownQuality="SMOOTH" elseif sinkFtMin<240 then self.touchdownQuality="FIRM" else self.touchdownQuality="HARD" end
 end
 self.touchdownTimer=math.max(0,self.touchdownTimer-d)
 l.TouchdownEvent=self.touchdownTimer>0
 l.TouchdownQuality=self.touchdownQuality
 local brakePressure=x.Brakes and tonumber(x.Brakes.BrakePressure) or 0
 l.BrakingActive=onGround and speed>3 and brakePressure>0
 l.ReverseThrust=onGround and speed>20 and (tonumber(x.ReverseThrust) or 0)>0
 if onGround then
  l.RolloutDistance=(tonumber(l.RolloutDistance) or 0)+speed*0.514444*d
  if speed<5 then l.Phase="GROUND"; l.Rollout=false else l.Phase="ROLLOUT"; l.Rollout=true end
 else
  l.RolloutDistance=0; l.Rollout=false
 end
 self.lastGround=onGround
end
return LandingDynamics
