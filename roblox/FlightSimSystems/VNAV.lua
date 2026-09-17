-- FlightSim VNAV vertical + speed guidance v2.0
-- Simulation approximation; not a certified FMC/VNAV implementation.
local VNAV={}; VNAV.__index=VNAV
local AircraftProfile=require(script.Parent.AircraftProfile)
local FT_PER_M=3.28084
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function distance(a,b) local dx,dz=b.X-a.X,b.Z-a.Z; return math.sqrt(dx*dx+dz*dz) end
local function constraintTarget(wp,cruise,targetFallback)
 local raw=wp and tonumber(wp.Altitude) or nil
 local explicit=finite(raw)
 local source="WAYPOINT"
 if not explicit then raw=tonumber(cruise); explicit=finite(raw); source=explicit and "CRUISE" or source end
 if not explicit then raw=tonumber(targetFallback); explicit=finite(raw); source=explicit and "SELECTED" or source end
 if not explicit then return nil,nil,"NONE" end
 local c=wp and string.upper(tostring(wp.AltitudeConstraint or "AT")) or "AT"
 if source~="WAYPOINT" then c="CRUISE" end
 local minAlt=wp and tonumber(wp.MinAltitude) or nil; local maxAlt=wp and tonumber(wp.MaxAltitude) or nil
 if source=="WAYPOINT" then
  if finite(minAlt) then raw=math.max(raw,minAlt) end
  if finite(maxAlt) then raw=math.min(raw,maxAlt) end
  if c=="ABOVE" then raw=math.max(raw,minAlt or raw) elseif c=="BELOW" then raw=math.min(raw,maxAlt or raw) end
 end
 return clamp(raw,0,60000),c,source
end
local function downstreamConstraint(route,index,aircraftAltitude,cruise)
 local totalM=0; local previous=route[index]
 if not previous or typeof(previous.Position)~="Vector3" then return nil end
 for i=index+1,#route do
  local wp=route[i]
  if not wp or typeof(wp.Position)~="Vector3" then break end
  totalM+=distance(previous.Position,wp.Position)
  local hasExplicit=finite(tonumber(wp.Altitude)) or finite(tonumber(wp.MinAltitude)) or finite(tonumber(wp.MaxAltitude))
  if hasExplicit then
   local target,c=constraintTarget(wp,nil,nil)
   if target and (c=="BELOW" and target<aircraftAltitude or c=="AT" and target<aircraftAltitude or c=="ABOVE" and target>aircraftAltitude) then return i,target,c,totalM end
  end
  previous=wp
 end
 return nil
end
local function downstreamTOD(route,index,aircraftAltitude)
 if not finite(aircraftAltitude) then return nil end
 local nextIndex,target,c,totalM=downstreamConstraint(route,index,aircraftAltitude,nil)
 if not nextIndex or not finite(target) or target>=aircraftAltitude then return nil end
 local requiredM=math.max(0,(aircraftAltitude-target)/math.tan(math.rad(3))/FT_PER_M)
 return math.max(0,totalM-requiredM),nextIndex,target,c
end
local function safeSpeedBounds(envelope)
 local vmo=tonumber(AircraftProfile.Limits and AircraftProfile.Limits.VMO)
 if not finite(vmo) then vmo=340 end
 local stall=tonumber(envelope.StallSpeedKt); local minimum=60
 if finite(stall) then minimum=math.max(minimum,stall+15) end
 return minimum,math.min(340,vmo)
end
function VNAV.new(state) return setmetatable({state=state,lastWaypoint=nil},VNAV) end
function VNAV:Step(dt)
 local x=self.state:Get(); local nav=x.Navigation or {}; local route=nav.Route or {}; local ap=x.Autopilot or {}; local fmc=x.FMC or {}
 x.VNAV=x.VNAV or {Mode="OFF",Phase="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=nil,ConstraintType=nil,ConstraintAltitude=nil,ConstraintSatisfied=true,TargetSpeed=nil,SpeedConstraintType=nil,SpeedConstraintSatisfied=true,TopOfDescentDistance=nil,GuidanceLimited=false,LimitReason=nil,ConstraintLookaheadIndex=nil,NextConstraintAltitude=nil,NextConstraintType=nil}
 local v=x.VNAV; v.GuidanceLimited=false; v.LimitReason=nil; v.ConstraintLookaheadIndex=nil; v.NextConstraintAltitude=nil; v.NextConstraintType=nil
 if v.Mode~="VNAV" then v.Mode="OFF"; v.Phase="OFF"; v.TargetAltitude=nil; v.VerticalSpeed=0; v.PathError=0; v.CommandVerticalSpeed=nil; v.ConstraintType=nil; v.ConstraintAltitude=nil; v.ConstraintSatisfied=true; v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true; v.TopOfDescentDistance=nil; self.lastWaypoint=nil; return true end
 v.Mode="VNAV"
 local index=math.max(1,math.floor(tonumber(nav.ActiveWaypoint) or 1)); local wp=route[index]; self.lastWaypoint=index
 local altitude=finite(x.Altitude) and x.Altitude or 0; local target,constraint,source=constraintTarget(wp,fmc.CruiseAltitude,ap.TargetAltitude)
 v.ConstraintType=target and constraint or nil; v.ConstraintAltitude=target; v.TargetAltitude=target
 local tolerance=(constraint=="AT" or constraint=="CRUISE") and 75 or 100
 if target then
  if constraint=="ABOVE" then v.ConstraintSatisfied=altitude+tolerance>=target elseif constraint=="BELOW" then v.ConstraintSatisfied=altitude-tolerance<=target else v.ConstraintSatisfied=math.abs(altitude-target)<=tolerance end
  v.PathError=target-altitude
 else v.ConstraintSatisfied=true; v.PathError=0 end
 local downstreamIndex,downstreamTarget,downstreamType,downstreamDistance=downstreamConstraint(route,index,altitude,nil)
 v.ConstraintLookaheadIndex=downstreamIndex; v.NextConstraintAltitude=downstreamTarget; v.NextConstraintType=downstreamType
 local distanceToWp=math.max(1,tonumber(nav.DistanceToWaypoint) or 1); local distanceFt=distanceToWp*FT_PER_M; local speed=math.max(60,tonumber(x.IndicatedAirspeed) or tonumber(x.Airspeed) or 60); local fps=speed*1.68781
 local tod=nil
 if source=="WAYPOINT" and target and altitude>target then
  local requiredM=math.max(0,(altitude-target)/math.tan(math.rad(3))/FT_PER_M); tod=math.max(0,distanceToWp-requiredM)
 elseif altitude<=target then
  tod=downstreamTOD(route,index,altitude)
 end
 if tod==nil and downstreamDistance and downstreamTarget and downstreamTarget<altitude then
  local requiredM=math.max(0,(altitude-downstreamTarget)/math.tan(math.rad(3))/FT_PER_M); tod=math.max(0,downstreamDistance-requiredM)
 end
 if target then
  v.TopOfDescentDistance=tod
  if v.PathError>tolerance then v.Phase="CLIMB" elseif v.PathError<-tolerance then v.Phase=(tod==nil or tod<=0) and "DESCENT" or "CRUISE" else v.Phase="ALTITUDE_CAPTURE" end
 else
  v.Phase=(downstreamTarget and downstreamTarget<altitude and (tod or 0)<=0) and "DESCENT" or "CRUISE"; v.TopOfDescentDistance=tod
 end
 local pathAngle=0
 if target then
  if v.Phase=="DESCENT" then pathAngle=-math.rad(3) elseif v.Phase=="CLIMB" then pathAngle=math.atan2(v.PathError,distanceFt) else pathAngle=math.atan2(v.PathError,math.max(distanceFt,3040)) end
  pathAngle=clamp(pathAngle,-math.rad(6),math.rad(6))
 elseif downstreamTarget and downstreamTarget<altitude and (tod or 0)<=0 then pathAngle=-math.rad(3) end
 local desiredVS=math.tan(pathAngle)*fps*60
 if distanceToWp<1000 then desiredVS=clamp(desiredVS,-800,800) elseif distanceToWp<5000 then desiredVS=clamp(desiredVS,-1800,1800) else desiredVS=clamp(desiredVS,-2500,2500) end
 if v.Phase=="CRUISE" or math.abs(v.PathError)<75 then desiredVS=clamp(v.PathError*0.08,-800,800) end
 if constraint=="ABOVE" and altitude<target then desiredVS=math.max(desiredVS,0) elseif constraint=="BELOW" and altitude>target then desiredVS=math.min(desiredVS,0) end
 local envelope=x.FlightEnvelope or {}
 if finite(envelope.StallMarginKt) and envelope.StallMarginKt<0 then desiredVS=math.max(desiredVS,-500); v.GuidanceLimited=true; v.LimitReason="STALL_MARGIN" elseif envelope.Overspeed==true then desiredVS=math.min(desiredVS,500); v.GuidanceLimited=true; v.LimitReason="OVERSPEED" end
 desiredVS=clamp(desiredVS,-2500,2500)
 v.VerticalSpeed=desiredVS; v.CommandVerticalSpeed=desiredVS; v.DescentPathAngle=math.deg(pathAngle); nav.CommandAltitude=target; nav.CommandVerticalSpeed=desiredVS
 local rawSpeed=wp and tonumber(wp.Speed) or nil; local speedConstraint=wp and string.upper(tostring(wp.SpeedConstraint or "AT")) or "AT"
 local minSafeSpeed,maxSafeSpeed=safeSpeedBounds(envelope)
 if finite(rawSpeed) then
  local requested=clamp(rawSpeed,60,maxSafeSpeed); local targetSpeed=requested
  if requested<minSafeSpeed then targetSpeed=minSafeSpeed; v.GuidanceLimited=true; v.LimitReason=v.LimitReason or "STALL_MARGIN" end
  if speedConstraint=="BELOW" and targetSpeed>requested then v.GuidanceLimited=true; v.LimitReason=v.LimitReason or "STALL_MARGIN" end
  v.TargetSpeed=targetSpeed; v.SpeedConstraintType=speedConstraint; local speedTolerance=5
  if speedConstraint=="ABOVE" then v.SpeedConstraintSatisfied=speed+speedTolerance>=targetSpeed elseif speedConstraint=="BELOW" then v.SpeedConstraintSatisfied=speed-speedTolerance<=targetSpeed else v.SpeedConstraintSatisfied=math.abs(speed-targetSpeed)<=speedTolerance end
 elseif finite(ap.TargetSpeed) then
  v.TargetSpeed=clamp(ap.TargetSpeed,minSafeSpeed,maxSafeSpeed); v.SpeedConstraintType="SELECTED"; v.SpeedConstraintSatisfied=math.abs(speed-v.TargetSpeed)<=5
 else v.TargetSpeed=nil; v.SpeedConstraintType=nil; v.SpeedConstraintSatisfied=true end
 return true
end
return VNAV
