-- FlightSim landing gear system v0.8
-- Simulation approximation of hydraulic gear actuation, lock state and demand reporting.
-- Gear handle is represented by Gear.Nose/Left/Right; GearPosition is the physical state.
-- Alternate/manual extension is intentionally modeled as a separate capability rather than
-- silently treating standby hydraulic pressure as a normal gear-extension source.
local LandingGear={}; LandingGear.__index=LandingGear
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function pressure(system)
 if type(system)=="table" then return math.max(tonumber(system.Pressure) or 0,0) end
 return math.max(tonumber(system) or 0,0)
end
function LandingGear.new(state) return setmetatable({state=state},LandingGear) end
function LandingGear:Step(dt)
 local x=self.state:Get(); local gear=x.Gear or {}; local h=x.Hydraulic or {}; local failures=x.FailureEffects or {}; dt=math.max(tonumber(dt) or 0,0)
 local pressureA=failures.HydraulicAFailed==true and 0 or pressure(h.A)
 local pressureB=failures.HydraulicBFailed==true and 0 or pressure(h.B)
 local hydraulic=math.max(pressureA,pressureB); local powered=hydraulic>=1000
 x.GearPosition=x.GearPosition or {Nose=0,Left=0,Right=0}
 local rate=powered and 0.55 or 0
 local function move(k,target)
  local current=clamp(tonumber(x.GearPosition[k]) or 0,0,1)
  if rate<=0 then return current end
  local delta=rate*dt
  if math.abs(target-current)<=delta then return target end
  return clamp(current+(target>current and delta or -delta),0,1)
 end
 local targetNose=gear.Nose==true and 1 or 0
 local targetLeft=gear.Left==true and 1 or 0
 local targetRight=gear.Right==true and 1 or 0
 x.GearPosition.Nose=move("Nose",targetNose)
 x.GearPosition.Left=move("Left",targetLeft)
 x.GearPosition.Right=move("Right",targetRight)
 local nose=clamp(x.GearPosition.Nose,0,1); local left=clamp(x.GearPosition.Left,0,1); local right=clamp(x.GearPosition.Right,0,1)
 local transitioning=(nose>0.02 and nose<0.98) or (left>0.02 and left<0.98) or (right>0.02 and right<0.98)
 local downLocked=nose>=0.98 and left>=0.98 and right>=0.98
 local upLocked=nose<=0.02 and left<=0.02 and right<=0.02
 local unsafe=not downLocked and not upLocked
 local extensionDemand=transitioning and 0.85 or 0
 x.GearStatus={Nose=nose,Left=left,Right=right,DownLocked=downLocked,UpLocked=upLocked,Transitioning=transitioning,Unsafe=unsafe,HydraulicAvailable=powered,AlternateExtension=false,Warning=unsafe}
 x.HydraulicDemand=x.HydraulicDemand or {}
 x.HydraulicDemand.LandingGear=extensionDemand
 -- Standby hydraulic is deliberately not substituted for normal gear actuation here.
 -- Alternate/manual extension must be commanded and modeled explicitly in a later layer.
end
return LandingGear
