-- FlightSim autothrottle speed-management controller v0.6
-- Closed-loop game simulation; not certified Boeing autothrottle logic.
local Config=require(script.Parent.Config)
local AutoThrottle={}; AutoThrottle.__index=AutoThrottle
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function slew(current,target,rate,dt) local d=math.max(0,rate)*math.max(0,tonumber(dt) or 0); if target>current then return math.min(target,current+d) else return math.max(target,current-d) end end
local function engineAvailable(e) return e and (e.Running==true or (finite(e.N1) and e.N1>0)) and e.StartFailed~=true end
function AutoThrottle.new(state) return setmetatable({state=state},AutoThrottle) end
function AutoThrottle:SetEnabled(enabled)
 local x=self.state:Get(); x.AutoThrottle=x.AutoThrottle or {Enabled=false,Active=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF",Protection="NONE"}
 x.AutoThrottle.Enabled=enabled==true; x.AutoThrottle.Active=false; x.AutoThrottle.Protection="NONE"
 if not x.AutoThrottle.Enabled then x.AutoThrottle.Mode="OFF"; x.AutoThrottle.TargetSpeed=nil end
 return true
end
function AutoThrottle:GoAround()
 local x=self.state:Get(); local a=x.AutoThrottle or {}; x.AutoThrottle=a; a.Enabled=true; a.Active=true; a.Mode="TOGA"; a.Protection="TOGA"
 local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0); a.TargetSpeed=clamp(math.max(120,speed+20),120,180); a.SpeedError=a.TargetSpeed-speed; a.ThrottleCommand=a.ThrottleCommand or {[1]=0,[2]=0}
 for i=1,2 do local e=x.Engines and x.Engines[i]; if engineAvailable(e) then a.ThrottleCommand[i]=1; x.Throttle[i]=1 else a.ThrottleCommand[i]=0; x.Throttle[i]=0 end end
 return true
end
function AutoThrottle:Step(dt)
 local x=self.state:Get(); local ap=x.Autopilot or {}; local v=x.VNAV or {}; local a=x.AutoThrottle or {}
 x.AutoThrottle=a; a.ThrottleCommand=a.ThrottleCommand or {[1]=0,[2]=0}; a.Active=false; a.Protection=a.Protection or "NONE"
 if ap.GoAround==true or a.Mode=="TOGA" then
  local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0); a.Enabled=true; a.Active=true; a.Mode="TOGA"; a.Protection="TOGA"
  if not finite(a.TargetSpeed) then a.TargetSpeed=clamp(math.max(120,speed+20),120,180) end
  a.SpeedError=a.TargetSpeed-speed
  for i=1,2 do local e=x.Engines and x.Engines[i]; local ok=engineAvailable(e); a.ThrottleCommand[i]=ok and 1 or 0; x.Throttle[i]=a.ThrottleCommand[i] end
  return true
 end
 local selected=nil; local constraint="AT"
 if a.Enabled and ap.Enabled then
  if v.Mode=="VNAV" and finite(v.TargetSpeed) then selected=v.TargetSpeed; constraint=string.upper(tostring(v.SpeedConstraintType or "AT"))
  elseif finite(ap.TargetSpeed) then selected=ap.TargetSpeed; constraint="AT" end
 end
 if not selected then
  a.Enabled=false; a.TargetSpeed=nil; a.SpeedError=0; a.Mode="OFF"; a.Protection="NONE"; a.ThrottleCommand[1]=x.Throttle[1] or 0; a.ThrottleCommand[2]=x.Throttle[2] or 0; return true
 end
 selected=clamp(selected,60,350)
 local speed=math.max(0,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0)
 local controlTarget=selected
 if constraint=="ABOVE" and speed>=selected then controlTarget=speed elseif constraint=="BELOW" and speed<=selected then controlTarget=speed end
 local error=selected-speed
 local controlError=controlTarget-speed
 local maxAirspeed=tonumber(Config.MaxAirspeed) or 360
 local raw=clamp(0.50+controlError/80,0,1)
 local protection="NONE"
 if x.StallWarning==true or speed<selected-25 then raw=1; protection="UNDERSPEED"
 elseif speed>maxAirspeed-10 then raw=0; protection="OVERSPEED"
 elseif constraint=="BELOW" and speed>selected then raw=clamp(0.50+controlError/50,0,1)
 end
 local left=x.Engines and x.Engines[1]; local right=x.Engines and x.Engines[2]; local leftAvailable=engineAvailable(left); local rightAvailable=engineAvailable(right)
 if not leftAvailable and not rightAvailable then a.Enabled=false; a.Mode="NO_ENGINE"; a.Active=false; a.TargetSpeed=selected; a.SpeedError=error; a.Protection="NO_ENGINE"; return true end
 local availableCount=(leftAvailable and 1 or 0)+(rightAvailable and 1 or 0)
 local maxThrust=tonumber(Config.MaxThrust) or math.huge; local thrustScale=1
 if finite(maxThrust) and maxThrust>0 then local currentTotal=(left and tonumber(left.Thrust) or 0)+(right and tonumber(right.Thrust) or 0); if raw>0 and currentTotal>maxThrust then thrustScale=clamp(maxThrust/currentTotal,0,1) end end
 raw=clamp(raw*thrustScale,0,1)
 local rate=0.35
 a.ThrottleCommand[1]=slew(tonumber(a.ThrottleCommand[1]) or 0,leftAvailable and raw or 0,rate,dt); a.ThrottleCommand[2]=slew(tonumber(a.ThrottleCommand[2]) or 0,rightAvailable and raw or 0,rate,dt)
 x.Throttle[1]=a.ThrottleCommand[1]; x.Throttle[2]=a.ThrottleCommand[2]
 a.Active=true; a.TargetSpeed=selected; a.SpeedError=error; a.SpeedConstraintType=constraint; a.Protection=protection
 a.Mode=(v.Mode=="VNAV" and "VNAV_SPEED" or (availableCount==1 and "SINGLE_ENGINE_SPEED" or "SPEED"))
 return true
end
return AutoThrottle
