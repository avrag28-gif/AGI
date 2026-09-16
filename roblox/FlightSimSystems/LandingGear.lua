-- FlightSim landing gear system v0.3
-- Simulation approximation of hydraulic gear actuation and demand reporting.
local LandingGear={}; LandingGear.__index=LandingGear
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function LandingGear.new(state) return setmetatable({state=state},LandingGear) end
function LandingGear:Step(dt)
 local x=self.state:Get(); local gear=x.Gear or {}; local h=x.Hydraulic or {}
 local hydraulic=math.max(h.A or 0,h.B or 0); local powered=hydraulic>=1000
 x.GearPosition=x.GearPosition or {Nose=gear.Nose and 1 or 0,Left=gear.Left and 1 or 0,Right=gear.Right and 1 or 0}
 local rate=powered and 0.55 or 0
 local function move(k,target) x.GearPosition[k]=clamp(x.GearPosition[k]+(target-x.GearPosition[k])*math.min(1,rate*dt),0,1) end
 move("Nose",gear.Nose and 1 or 0); move("Left",gear.Left and 1 or 0); move("Right",gear.Right and 1 or 0)
 local transitioning=(x.GearPosition.Nose>0.02 and x.GearPosition.Nose<0.98) or (x.GearPosition.Left>0.02 and x.GearPosition.Left<0.98) or (x.GearPosition.Right>0.02 and x.GearPosition.Right<0.98)
 x.GearStatus={Nose=x.GearPosition.Nose,Left=x.GearPosition.Left,Right=x.GearPosition.Right,DownLocked=x.GearPosition.Nose>=0.98 and x.GearPosition.Left>=0.98 and x.GearPosition.Right>=0.98,UpLocked=x.GearPosition.Nose<=0.02 and x.GearPosition.Left<=0.02 and x.GearPosition.Right<=0.02,Transitioning=transitioning}
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.LandingGear=transitioning and 0.85 or 0
end
return LandingGear
