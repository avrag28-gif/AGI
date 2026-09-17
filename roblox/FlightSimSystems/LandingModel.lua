-- FlightSim takeoff / landing state machine v0.6
-- LandingModel owns phase/flare state; LandingDynamics owns touchdown contact/event classification.
-- Normal ground/rollout state is based on actual wheel contact, not raw GroundContact.
local LandingModel={}; LandingModel.__index=LandingModel
function LandingModel.new(state) return setmetatable({state=state,lastWheelContact=nil,flareActive=false,initialized=false},LandingModel) end
function LandingModel:Step(dt)
 local x=self.state:Get(); local l=x.Landing or {}; local gear=x.GearStatus or {}; local down=gear.DownLocked==true
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local agl=math.max(tonumber(x.Altitude) or 0,0); local vs=tonumber(x.VerticalSpeed) or 0
 local rawGround=x.GroundContact==true; local wheelContact=rawGround and down; local goAround=l.GoAround==true
 local d=math.max(tonumber(dt) or 0,0)
 if not self.initialized then
  self.lastWheelContact=wheelContact; self.initialized=true
  l.Takeoff=false; l.Flare=false
  l.Phase=wheelContact and (speed<5 and "GROUND" or "ROLLOUT") or (goAround and "GO_AROUND" or "AIRBORNE")
  l.Rollout=wheelContact and speed>=5
  self.flareActive=false
  return true
 end
 l.Takeoff=false; l.Flare=false
 if wheelContact then
  if speed<5 then l.Phase="GROUND"; l.Rollout=false
  else l.Phase="ROLLOUT"; l.Rollout=true end
  self.flareActive=false
 elseif self.lastWheelContact then
  l.Takeoff=true; l.Phase=goAround and "GO_AROUND" or "AIRBORNE"; l.Rollout=false; self.flareActive=false
 else
  if goAround then
   self.flareActive=false; l.Phase="GO_AROUND"; l.Rollout=false
  else
   local eligible=down and speed>70 and agl<50 and vs<0
   if eligible then
    self.flareActive=true
    l.Flare=true; l.Phase="FLARE"
   elseif self.flareActive and agl<80 and vs<=0 then
    l.Flare=true; l.Phase="FLARE"
   else
    self.flareActive=false; l.Phase="AIRBORNE"; l.Rollout=false
   end
  end
 end
 self.lastWheelContact=wheelContact
 return true
end
return LandingModel
