-- FlightSim takeoff / landing state machine v0.1
local LandingModel={}; LandingModel.__index=LandingModel
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingModel.new(state) return setmetatable({state=state,lastGround=true},LandingModel) end
function LandingModel:Step(dt)
 local x=self.state:Get(); local l=x.Landing; local gear=x.GearStatus or {}; local down=gear.DownLocked==true; local speed=x.Airspeed or 0
 if x.GroundContact then
  if not self.lastGround then l.Touchdown=true; l.Takeoff=false; l.Phase="ROLLOUT" end
  if speed<5 then l.Phase="GROUND"; l.Rollout=false else l.Rollout=true; l.Phase="ROLLOUT" end
  l.Flare=false
 else
  if self.lastGround then l.Takeoff=true end
  l.Touchdown=false
  local agl=x.Altitude or 0
  local vs=x.VerticalSpeed or 0
  if agl<50 and vs<0 and speed>70 and down then l.Flare=true; l.Phase="FLARE" else l.Flare=false; l.Phase="AIRBORNE" end
  l.Rollout=false
 end
 self.lastGround=x.GroundContact
end
return LandingModel
