-- FlightSim VNAV vertical + speed guidance v1.4
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local FT_PER_M=3.28084
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function constraintTarget(wp,cruise,targetFallback)
 local raw=wp and tonumber(wp.Altitude) or nil
 if not finite(raw) then raw=tonumber(cruise) end
 if not finite(raw) then raw=tonumber(targetFallback) end
 if not finite(raw) then return nil,"AT" end
 local c=wp and string.upper(tostring(wp.AltitudeConstraint or "AT")) or "AT"
 local minAlt=wp and tonumber(wp.MinAltitude) or nil; local maxAlt=wp and tonumber(wp.MaxAltitude) or nil
 if finite(minAlt) then raw=math.max(raw,minAlt) end
 if finite(maxAlt) then raw=math.min(raw,maxAlt) end
 if c=="ABOVE" then raw=math.max(raw,minAlt or raw) elseif c=="BELOW" then raw=math.min(raw,maxAlt or raw) end
 return clamp(raw,0,60000),c
end
local function routeDistanceTo(route,startIndex,endIndex)
 local total=0; local previous=route[startIndex] and route[startIndex].Position
 if typeof(previous)~="Vector3" then return nil end
 for i=startIndex+1,math.min(endIndex,#route) do
  local position=route[i].Position
  if typeof(position)~="Vector3" then return nil end
  local dx,dz=position.X-previous.X,position.Z-previous.Z; total=total+math.sqrt(dx*dx+dz*dz); previous=position
 end
 return total
end
function VNAV.new(state) return setmetatable({state=state,lastWaypoint=nil},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}; local ap=x.Autopilot or {}; local fmc=x.FMC or {}
 x.VNAV=x.VNAV or {Mode="OFF",Phase="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=nil,ConstraintType=nil,ConstraintAltitude=nil,ConstraintSatisfied=true,TargetSpeed=nil,SpeedConstraintType=nil,SpeedConstraintSatisfied=true,TopOfDescentDistance=nil}
 local v=x.VNAV
 if v.Mode~="VNAV" then v.Mode="OFF"; v.Phase="OFF"; v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true; v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true; v.TopOfDescentDistance=nil; self.lastWaypoint=nil; return true end
 v.Mode="VNAV"
 local index=math.max(1,math.floor(tonumber(nav.ActiveWaypoint) or 1)); local wp=route[index]; local waypointChanged=self.lastWaypoint~=index; self.lastWaypoint=index
 local altitude=finite(x.Altitude) and x.Altitude or 0
 local target,constraint=constraintTarget(wp,fmc.CruiseAltitude,ap.TargetAltitude)
 v.ConstraintType=target and constraint or nil; v.ConstraintAltitude=target; v.TargetAltitude=target
 local tolerance=(constraint=="AT") and 75 or 100
 if target then
  if constraint=="ABOVE" then v.ConstraintSatisfied=altitude+tolerance>=target elseif constraint=="BELOW" then v.ConstraintSatisfied=altitude-tolerance<=target else v.ConstraintSatisfied=math.abs(altitude-target)<=tolerance end
  v.PathError=target-altitude
 else
  v.ConstraintSatisfied=true; v.PathError=0
 end
 local distance=math.max(1,tonumber(nav.DistanceToWaypoint) or 1); local distanceFt=distance*FT_PER_M; local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60); local fps=speed*1.68781
 local descentDistance=0
 if target and altitude>target then descentDistance=math.max(0,(altitude-target)/math.tan(math.rad(3))/FT_PER_M) end
 local todDistance=nil
 if target and altitude>target and altitude-target>tolerance then
  -- The active lower constraint determines the descent required before reaching it.
  todDistance=math.max(0,distance-descentDistance)
 elseif target and altitude<=target+tolerance then
  -- At or below the active target, look ahead for the first lower constraint.
  local cumulative=0
  for j=index+1,#route do
   local nextWp=route[j]; local nextAltitude=nextWp and tonumber(nextWp.Altitude); local leg=routeDistanceTo(route,j-1,j)
   if leg==nil then break end
   cumulative=cumulative+leg
   if finite(nextAltitude) and nextAltitude<altitude-tolerance then
    local required=math.max(0,(altitude-nextAltitude)/math.tan(math.rad(3))/FT_PER_M); todDistance=math.max(0,cumulative-required); break
   end
  end
 end
 if target then
  v.TopOfDescentDistance=todDistance
  if v.PathError>tolerance then v.Phase="CLIMB"
  elseif v.PathError<-tolerance then v.Phase=(todDistance~=nil and todDistance>0) and "CRUISE" or "DESCENT"
  else v.Phase="ALTITUDE_CAPTURE" end
 else
  v.Phase="CRUISE"; v.TopOfDescentDistance=nil
 end
 local pathAngle=0
 if target then
  if v.Phase=="DESCENT" then pathAngle=-math.rad(3) elseif v.Phase=="CLIMB" then pathAngle=math.atan2(v.PathError,distanceFt) else pathAngle=math.atan2(v.PathError,math.max(distanceFt,3040)) end
  pathAngle=clamp(pathAngle,-math.rad(6),math.rad(6))
 end
 local desiredVS=math.tan(pathAngle)*fps*60
 if distance<1000 then desiredVS=clamp(desiredVS,-800,800) elseif distance<5000 then desiredVS=clamp(desiredVS,-1800,1800) else desiredVS=clamp(desiredVS,-2500,2500) end
 if v.Phase=="CRUISE" or math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 if constraint=="ABOVE" and altitude<target then desiredVS=math.max(desiredVS,0) elseif constraint=="BELOW" and altitude>target then desiredVS=math.min(desiredVS,0) end
 v.VerticalSpeed=desiredVS; v.CommandVerticalSpeed=desiredVS; v.DescentPathAngle=math.deg(pathAngle)
 nav.CommandAltitude=target; nav.CommandVerticalSpeed=desiredVS
 local rawSpeed=wp and tonumber(wp.Speed) or nil; local speedConstraint=wp and string.upper(tostring(wp.SpeedConstraint or "AT")) or "AT"
 if finite(rawSpeed) then
  local targetSpeed=clamp(rawSpeed,60,350); v.TargetSpeed=targetSpeed; v.SpeedConstraintType=speedConstraint; local speedTolerance=5
  if speedConstraint=="ABOVE" then v.SpeedConstraintSatisfied=speed+speedTolerance>=targetSpeed elseif speedConstraint=="BELOW" then v.SpeedConstraintSatisfied=speed-speedTolerance<=targetSpeed else v.SpeedConstraintSatisfied=math.abs(speed-targetSpeed)<=speedTolerance end
 elseif finite(ap.TargetSpeed) then
  v.TargetSpeed=clamp(ap.TargetSpeed,60,350); v.SpeedConstraintType="SELECTED"; v.SpeedConstraintSatisfied=math.abs(speed-v.TargetSpeed)<=5
 else
  v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true
 end
 if waypointChanged then v.PathError=target and (target-altitude) or 0 end
 return true
end
return VNAV
