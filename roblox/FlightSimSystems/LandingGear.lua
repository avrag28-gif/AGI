-- FlightSim landing gear system v0.2
local LandingGear={}; LandingGear.__index=LandingGear
function LandingGear.new(state) return setmetatable({state=state},LandingGear) end
function LandingGear:Step(dt)
 local x=self.state:Get(); local gear=x.Gear
 local hydraulic=math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)
 local powered=hydraulic>=1000
 x.GearPosition=x.GearPosition or {Nose=gear.Nose and 1 or 0,Left=gear.Left and 1 or 0,Right=gear.Right and 1 or 0}
 local rate=powered and 0.55 or 0
 local function move(k,target) x.GearPosition[k]=math.max(0,math.min(1,x.GearPosition[k]+(target-x.GearPosition[k])*math.min(1,rate*dt))) end
 move("Nose",gear.Nose and 1 or 0); move("Left",gear.Left and 1 or 0); move("Right",gear.Right and 1 or 0)
 x.GearStatus={Nose=x.GearPosition.Nose,Left=x.GearPosition.Left,Right=x.GearPosition.Right,DownLocked=x.GearPosition.Nose>=0.98 and x.GearPosition.Left>=0.98 and x.GearPosition.Right>=0.98,UpLocked=x.GearPosition.Nose<=0.02 and x.GearPosition.Left<=0.02 and x.GearPosition.Right<=0.02,Transitioning=(x.GearPosition.Nose>0.02 and x.GearPosition.Nose<0.98) or (x.GearPosition.Left>0.02 and x.GearPosition.Left<0.98) or (x.GearPosition.Right>0.02 and x.GearPosition.Right<0.98)}
end
return LandingGear
