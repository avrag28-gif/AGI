-- FlightSim autothrottle speed-management foundation v0.2
-- Closed-loop game simulation; not certified Boeing autothrottle logic.
local AutoThrottle={}; AutoThrottle.__index=AutoThrottle
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function slew(current,target,rate,dt) local d=math.max(0,rate)*math.max(0,tonumber(dt) or 0); if target>current then return math.min(target,current+d) else return math.max(target,current-d) end end
function AutoThrottle.new(state) return setmetatable({state=state},AutoThrottle) end
function AutoThrottle:SetEnabled(enabled)
 local x=self.state:Get(); x.AutoThrottle=x.AutoThrottle or {Enabled=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF"}; x.AutoThrottle.Enabled=enabled==true
 if not x.AutoThrottle.Enabled then x.AutoThrottle.Mode="OFF"; x.AutoThrottle.TargetSpeed=nil end
 return true
end
function AutoThrottle:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local v=x.VNAV or {}; local a=x.AutoThrottle or {}
 x.AutoThrottle=a; a.ThrottleCommand=a.ThrottleCommand or {[1]=0,[2]=0}
 local target=nil
 if a.Enabled and ap.Enabled then
  if v.Mode=="VNAV" and finite(v.TargetSpeed) then target=v.TargetSpeed elseif finite(ap.TargetSpeed) then target=ap.TargetSpeed end
 end
 if not target then
  a.Enabled=false; a.TargetSpeed=nil; a.SpeedError=0; a.Mode="OFF"; a.ThrottleCommand[1]=x.Throttle[1] or 0; a.ThrottleCommand[2]=x.Throttle[2] or 0; return true
 end
 target=clamp(target,60,350)
 local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0); local error=target-speed
 local raw=clamp(0.50+error/80,0,1)
 local left=x.Engines and x.Engines[1]; local right=x.Engines and x.Engines[2]
 local leftAvailable=left and (left.Running==true or left.N1>0) and not (left.StartFailed==true); local rightAvailable=right and (right.Running==true or right.N1>0) and not (right.StartFailed==true)
 if not leftAvailable and not rightAvailable then a.Enabled=false; a.Mode="NO_ENGINE"; a.TargetSpeed=target; a.SpeedError=error; return true end
 local rate=0.35
 a.ThrottleCommand[1]=slew(tonumber(a.ThrottleCommand[1]) or 0,leftAvailable and raw or 0,rate,dt)
 a.ThrottleCommand[2]=slew(tonumber(a.ThrottleCommand[2]) or 0,rightAvailable and raw or 0,rate,dt)
 x.Throttle[1]=a.ThrottleCommand[1]; x.Throttle[2]=a.ThrottleCommand[2]
 a.TargetSpeed=target; a.SpeedError=error; a.Mode=(v.Mode=="VNAV" and "VNAV_SPEED" or "SPEED")
 return true
end
return AutoThrottle
