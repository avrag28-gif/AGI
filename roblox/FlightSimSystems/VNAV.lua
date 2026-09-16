-- FlightSim VNAV vertical + speed guidance v0.9
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
function VNAV.new(state) return setmetatable({state=state},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}; local ap=x.Autopilot or {}
 x.VNAV=x.VNAV or {Mode="OFF",Phase="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=nil,ConstraintType=nil,ConstraintAltitude=nil,ConstraintSatisfied=true,TargetSpeed=nil,SpeedConstraintType=nil,SpeedConstraintSatisfied=true,TopOfDescentDistance=nil}
 local v=x.VNAV
 if v.Mode~="VNAV" then v.Mode="OFF"; v.Phase="OFF"; v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true; v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true; v.TopOfDescentDistance=nil; return true end
 v.Mode="VNAV"
 local wp=route[nav.ActiveWaypoint]
 local altitude=finite(x.Altitude) and x.Altitude or 0
 local rawTarget=wp and tonumber(wp.Altitude) or nil
 if not finite(rawTarget) then rawTarget=tonumber(x.FMC and x.FMC.CruiseAltitude) end
 if not finite(rawTarget) then rawTarget=tonumber(ap.TargetAltitude) end
 local constraint=wp and string.upper(tostring(wp.AltitudeConstraint or "AT")) or "AT"
 local minAlt=wp and tonumber(wp.MinAltitude) or nil
 local maxAlt=wp and tonumber(wp.MaxAltitude) or nil
 local target=finite(rawTarget) and rawTarget or nil
 if finite(minAlt) then target=math.max(target or minAlt,minAlt) end
 if finite(maxAlt) then target=math.min(target or maxAlt,maxAlt) end
 if finite(target) then
  if constraint=="ABOVE" then target=math.max(target,minAlt or target) elseif constraint=="BELOW" then target=math.min(target,maxAlt or target) end
  v.TargetAltitude=clamp(target,0,60000); v.ConstraintType=constraint; v.ConstraintAltitude=v.TargetAltitude
  local tolerance=(constraint=="AT") and 75 or 100
  if constraint=="ABOVE" then v.ConstraintSatisfied=altitude+tolerance>=v.TargetAltitude elseif constraint=="BELOW" then v.ConstraintSatisfied=altitude-tolerance<=v.TargetAltitude else v.ConstraintSatisfied=math.abs(altitude-v.TargetAltitude)<=tolerance end
  v.PathError=v.TargetAltitude-altitude
 else
  v.Phase="CRUISE"; v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true; v.TopOfDescentDistance=nil
 end
 local distance=math.max(1,tonumber(nav.DistanceToWaypoint) or 1)
 local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60)
 local fps=speed*1.68781
 local tolerance=(constraint=="AT") and 75 or 100
 if v.TargetAltitude then
  local descentDistance=math.max(0,(altitude-v.TargetAltitude)/math.tan(math.rad(3)))
  v.TopOfDescentDistance=(v.PathError<0 and descentDistance or nil)
  if v.PathError>tolerance then v.Phase="CLIMB"
  elseif v.PathError<-tolerance then v.Phase=(distance<=descentDistance+926 and "DESCENT" or "CRUISE")
  else v.Phase="ALTITUDE_CAPTURE" end
 else v.TopOfDescentDistance=nil end
 local pathAngle=0
 if v.TargetAltitude then
  if v.Phase=="DESCENT" then pathAngle=-math.rad(3) elseif v.Phase=="CLIMB" then pathAngle=math.atan2(v.PathError,distance) else pathAngle=math.atan2(v.PathError,math.max(distance,926)) end
  pathAngle=clamp(pathAngle,-math.rad(6),math.rad(6))
 end
 local desiredVS=math.tan(pathAngle)*fps*60
 if distance<1000 then desiredVS=clamp(desiredVS,-800,800) elseif distance<5000 then desiredVS=clamp(desiredVS,-1800,1800) else desiredVS=clamp(desiredVS,-2500,2500) end
 if v.Phase=="CRUISE" or math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 if constraint=="ABOVE" and altitude<v.TargetAltitude then desiredVS=math.max(desiredVS,0) elseif constraint=="BELOW" and altitude>v.TargetAltitude then desiredVS=math.min(desiredVS,0) end
 v.VerticalSpeed=desiredVS; v.CommandVerticalSpeed=desiredVS; v.DescentPathAngle=math.deg(pathAngle)
 nav.CommandAltitude=v.TargetAltitude; nav.CommandVerticalSpeed=desiredVS
 local rawSpeed=wp and tonumber(wp.Speed) or nil
 local speedConstraint=wp and string.upper(tostring(wp.SpeedConstraint or "AT")) or "AT"
 if finite(rawSpeed) then
  local targetSpeed=clamp(rawSpeed,60,350); v.TargetSpeed=targetSpeed; v.SpeedConstraintType=speedConstraint
  local speedTolerance=5; local current=tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 0
  if speedConstraint=="ABOVE" then v.SpeedConstraintSatisfied=current+speedTolerance>=targetSpeed elseif speedConstraint=="BELOW" then v.SpeedConstraintSatisfied=current-speedTolerance<=targetSpeed else v.SpeedConstraintSatisfied=math.abs(current-targetSpeed)<=speedTolerance end
 elseif finite(ap.TargetSpeed) then
  v.TargetSpeed=clamp(ap.TargetSpeed,60,350); v.SpeedConstraintType="SELECTED"; v.SpeedConstraintSatisfied=math.abs(speed-v.TargetSpeed)<=5
 else v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true end
 return true
end
return VNAV
