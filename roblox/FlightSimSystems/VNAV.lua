-- FlightSim VNAV vertical + speed guidance v0.5
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function VNAV.new(state) return setmetatable({state=state},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}
 x.VNAV=x.VNAV or {Mode="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=nil,ConstraintType=nil,ConstraintAltitude=nil,ConstraintSatisfied=true,TargetSpeed=nil,SpeedConstraintType=nil,SpeedConstraintSatisfied=true}
 local v=x.VNAV
 if nav.Mode~="VNAV" then v.Mode="OFF"; v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true; v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true; return true end
 v.Mode="VNAV"
 local wp=route[nav.ActiveWaypoint]
 local altitude=finite(x.Altitude) and x.Altitude or 0
 local rawTarget=wp and tonumber(wp.Altitude) or tonumber(x.Autopilot and x.Autopilot.TargetAltitude)
 local constraint=wp and string.upper(tostring(wp.AltitudeConstraint or (wp.Altitude and "AT" or "AT"))) or "AT"
 local minAlt=wp and tonumber(wp.MinAltitude) or nil
 local maxAlt=wp and tonumber(wp.MaxAltitude) or nil
 local target
 if finite(minAlt) then target=minAlt end
 if finite(maxAlt) then target=finite(target) and math.min(target,maxAlt) or maxAlt end
 if finite(rawTarget) then
  if constraint=="ABOVE" then target=math.max(target or rawTarget,rawTarget)
  elseif constraint=="BELOW" then target=math.min(target or rawTarget,rawTarget)
  else target=rawTarget end
 end
 if not finite(target) then v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true
 else
  v.TargetAltitude=clamp(target,0,60000); v.ConstraintType=constraint; v.ConstraintAltitude=v.TargetAltitude
  local tolerance=(constraint=="AT") and 75 or 100
  if constraint=="ABOVE" then v.ConstraintSatisfied=altitude+tolerance>=v.TargetAltitude elseif constraint=="BELOW" then v.ConstraintSatisfied=altitude-tolerance<=v.TargetAltitude else v.ConstraintSatisfied=math.abs(altitude-v.TargetAltitude)<=tolerance end
  v.PathError=v.TargetAltitude-altitude
 end
 local distance=math.max(1,tonumber(nav.DistanceToWaypoint) or 1)
 local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60)
 local fps=speed*1.68781
 local pathAngle=0
 if v.TargetAltitude then pathAngle=math.atan2(v.PathError,distance); pathAngle=clamp(pathAngle,-math.rad(6),math.rad(6)) end
 local desiredVS=math.tan(pathAngle)*fps*60
 if distance<1000 then desiredVS=clamp(desiredVS,-800,800) elseif distance<5000 then desiredVS=clamp(desiredVS,-1800,1800) else desiredVS=clamp(desiredVS,-2500,2500) end
 if math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 if constraint=="ABOVE" and altitude<v.TargetAltitude then desiredVS=math.max(desiredVS,0) elseif constraint=="BELOW" and altitude>v.TargetAltitude then desiredVS=math.min(desiredVS,0) end
 v.VerticalSpeed=desiredVS; v.CommandVerticalSpeed=desiredVS; v.DescentPathAngle=math.deg(pathAngle)
 nav.CommandAltitude=v.TargetAltitude; nav.CommandVerticalSpeed=desiredVS
 local rawSpeed=wp and tonumber(wp.Speed) or nil
 local speedConstraint=wp and string.upper(tostring(wp.SpeedConstraint or (finite(rawSpeed) and "AT" or "AT"))) or "AT"
 if finite(rawSpeed) then
  local targetSpeed=clamp(rawSpeed,60,350); v.TargetSpeed=targetSpeed; v.SpeedConstraintType=speedConstraint
  local speedTolerance=5; local current=tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0
  if speedConstraint=="ABOVE" then v.SpeedConstraintSatisfied=current+speedTolerance>=targetSpeed elseif speedConstraint=="BELOW" then v.SpeedConstraintSatisfied=current-speedTolerance<=targetSpeed else v.SpeedConstraintSatisfied=math.abs(current-targetSpeed)<=speedTolerance end
 elseif finite(x.Autopilot and x.Autopilot.TargetSpeed) then
  v.TargetSpeed=clamp(x.Autopilot.TargetSpeed,60,350); v.SpeedConstraintType="SELECTED"; v.SpeedConstraintSatisfied=math.abs(speed-v.TargetSpeed)<=5
 else
  v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true
 end
 return true
end
return VNAV
