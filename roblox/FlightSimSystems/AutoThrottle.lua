-- FlightSim autothrottle speed-management foundation v0.1
-- Closed-loop game simulation; not certified Boeing autothrottle logic.
local AutoThrottle={}; AutoThrottle.__index=AutoThrottle
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function AutoThrottle.new(state) return setmetatable({state=state},AutoThrottle) end
function AutoThrottle:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local v=x.VNAV or {}
 x.AutoThrottle=x.AutoThrottle or {Enabled=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF"}
 local a=x.AutoThrottle
 local target=nil
 if ap.Enabled and v.Mode=="VNAV" and finite(v.TargetSpeed) then target=v.TargetSpeed
 elseif ap.Enabled and finite(ap.TargetSpeed) then target=ap.TargetSpeed end
 if not target then
  a.Enabled=false; a.TargetSpeed=nil; a.SpeedError=0; a.ThrottleCommand[1]=x.Throttle[1] or 0; a.ThrottleCommand[2]=x.Throttle[2] or 0; a.Mode="OFF"; return true
 end
 target=clamp(target,60,350)
 local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0)
 local error=target-speed
 local command=clamp(0.5+error/80,0,1)
 local maxThrottle=1
 if v.Mode=="VNAV" and v.TargetAltitude and tonumber(x.Altitude) and x.Altitude<v.TargetAltitude-100 then maxThrottle=1 end
 command=clamp(command,0,maxThrottle)
 a.Enabled=true; a.TargetSpeed=target; a.SpeedError=error; a.Mode=(v.Mode=="VNAV" and "VNAV_SPEED" or "SPEED")
 a.ThrottleCommand[1]=command; a.ThrottleCommand[2]=command
 x.Throttle[1]=command; x.Throttle[2]=command
 return true
end
return AutoThrottle
