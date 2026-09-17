-- FlightSim landing dynamics v0.5
-- LandingDynamics is the canonical owner of wheel contact, touchdown event and touchdown quality.
-- LandingModel owns phase/flare/rollout state; LandingDynamics owns contact metrics and rollout distance.
-- Units: Airspeed=kt, VerticalSpeed=ft/min, RolloutDistance=m.
local LandingDynamics={}; LandingDynamics.__index=LandingDynamics
function LandingDynamics.new(state)
 return setmetatable({state=state,lastWheelContact=nil,touchdownTimer=0,touchdownQuality="NONE",initialized=false},LandingDynamics)
end
function LandingDynamics:Step(dt)
 local x=self.state:Get(); local l=x.Landing or {}; local gear=x.GearStatus or {}; local onGround=x.GroundContact==true
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local verticalSpeed=tonumber(x.VerticalSpeed) or 0; local sinkFtMin=math.max(-verticalSpeed,0); local gearDown=gear.DownLocked==true
 local wheelContact=onGround and gearDown
 local d=math.max(tonumber(dt) or 0,0)
 if not self.initialized then self.lastWheelContact=wheelContact; self.initialized=true end
 l.WheelContact=wheelContact
 l.Touchdown=false
 -- A normal touchdown event is a transition into actual wheel contact.
 -- Raw GroundContact alone is insufficient because it can occur with the gear not down.
 if wheelContact and self.lastWheelContact==false then
  l.Touchdown=true; self.touchdownTimer=1.0
  if sinkFtMin<120 then self.touchdownQuality="SMOOTH" elseif sinkFtMin<240 then self.touchdownQuality="FIRM" else self.touchdownQuality="HARD" end
 end
 self.touchdownTimer=math.max(0,self.touchdownTimer-d)
 l.TouchdownEvent=self.touchdownTimer>0
 l.TouchdownQuality=self.touchdownQuality
 local brakePressure=x.Brakes and tonumber(x.Brakes.BrakePressure) or 0
 l.BrakingActive=wheelContact and speed>3 and brakePressure>0
 l.ReverseThrust=wheelContact and speed>20 and (tonumber(x.ReverseThrust) or 0)>0
 if wheelContact then l.RolloutDistance=(tonumber(l.RolloutDistance) or 0)+speed*0.514444*d else l.RolloutDistance=0 end
 self.lastWheelContact=wheelContact
end
return LandingDynamics
