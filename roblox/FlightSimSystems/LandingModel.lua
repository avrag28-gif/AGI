-- FlightSim takeoff / landing state machine v0.2
local LandingModel={}; LandingModel.__index=LandingModel
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingModel.new(state) return setmetatable({state=state,lastGround=true,flareActive=false},LandingModel) end
function LandingModel:Step(dt)
 local x=self.state:Get(); local l=x.Landing; local gear=x.GearStatus or {}; local down=gear.DownLocked==true
 local speed=math.max(x.Airspeed or 0,0); local agl=math.max(x.Altitude or 0,0); local vs=x.VerticalSpeed or 0
 local onGround=x.GroundContact==true
 l.Takeoff=false; l.Touchdown=false; l.Flare=false
 if onGround then
  if not self.lastGround then l.Touchdown=true; l.TouchdownEvent=true end
  if speed<5 then l.Phase="GROUND"; l.Rollout=false; l.RolloutDistance=0
  else l.Phase="ROLLOUT"; l.Rollout=true end
  self.flareActive=false
 elseif self.lastGround then
  l.Takeoff=true; l.Phase="AIRBORNE"; self.flareActive=false
 else
  local eligible=down and speed>70 and agl<50 and vs<0
  if eligible then
   self.flareActive=true
   l.Flare=true; l.Phase="FLARE"
  elseif self.flareActive and agl<80 and vs<=0 then
   l.Flare=true; l.Phase="FLARE"
  else
   self.flareActive=false; l.Phase="AIRBORNE"
  end
 end
 self.lastGround=onGround
end
return LandingModel
