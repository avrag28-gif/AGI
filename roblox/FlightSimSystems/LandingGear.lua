-- FlightSim landing gear system v0.5
-- Simulation approximation of hydraulic gear actuation, lock state and demand reporting.
-- Gear handle is represented by Gear.Nose/Left/Right; GearPosition is the physical state.
local LandingGear={}; LandingGear.__index=LandingGear
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingGear.new(state) return setmetatable({state=state},LandingGear) end
function LandingGear:Step(dt)
 local x=self.state:Get(); local gear=x.Gear or {}; local h=x.Hydraulic or {}; dt=math.max(tonumber(dt) or 0,0)
 local pressureA=math.max(tonumber(h.A) or 0,0); local pressureB=math.max(tonumber(h.B) or 0,0); local hydraulic=math.max(pressureA,pressureB); local powered=hydraulic>=1000
 x.GearPosition=x.GearPosition or {Nose=0,Left=0,Right=0}
 local rate=powered and 0.55 or 0
 local function move(k,target)
  local current=clamp(tonumber(x.GearPosition[k]) or 0,0,1)
  if rate<=0 then return current end
  local delta=rate*dt
  if math.abs(target-current)<=delta then return target end
  return clamp(current+(target>current and delta or -delta),0,1)
 end
 x.GearPosition.Nose=move("Nose",gear.Nose==true and 1 or 0)
 x.GearPosition.Left=move("Left",gear.Left==true and 1 or 0)
 x.GearPosition.Right=move("Right",gear.Right==true and 1 or 0)
 local nose=clamp(x.GearPosition.Nose,0,1); local left=clamp(x.GearPosition.Left,0,1); local right=clamp(x.GearPosition.Right,0,1)
 local transitioning=(nose>0.02 and nose<0.98) or (left>0.02 and left<0.98) or (right>0.02 and right<0.98)
 local downLocked=nose>=0.98 and left>=0.98 and right>=0.98; local upLocked=nose<=0.02 and left<=0.02 and right<=0.02
 local unsafe=not downLocked and not upLocked
 x.GearStatus={Nose=nose,Left=left,Right=right,DownLocked=downLocked,UpLocked=upLocked,Transitioning=transitioning,Unsafe=unsafe,HydraulicAvailable=powered}
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.LandingGear=transitioning and 0.85 or 0
end
return LandingGear
