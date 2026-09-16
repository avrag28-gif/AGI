-- FlightSim aerodynamic / ground dynamics foundation v1.8
-- Game simulation model; coefficients are tunable approximations, not certified aircraft data.
local Config=require(script.Parent.Config)
local Physics={}; Physics.__index=Physics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
function Physics.new(state) return setmetatable({state=state},Physics) end
function Physics:Step(dt)
 local x=self.state:Get(); local s=x.Surface or {}; local e1=x.Engines[1]; local e2=x.Engines[2]
 local speedKts=math.max(x.Airspeed or 0,0); local speedMS=speedKts*0.514444
 local mass=90000+math.max(0,x.Fuel.Total or 0)*0.8; local weight=mass*9.80665
 local throttle=(clamp(x.Throttle[1] or 0,0,1)+clamp(x.Throttle[2] or 0,0,1))*0.5
 local leftThrust=math.max(0,e1.Thrust or 0); local rightThrust=math.max(0,e2.Thrust or 0); local thrust=leftThrust+rightThrust
 local ground=x.GroundContact==true
 local reverse=ground and clamp(x.ReverseThrust or 0,0,1) or 0
 local flap=clamp(s.Flap or 0,0,1)
 local gear=x.GearPosition or {}; local gearExposed=clamp(((gear.Nose or 0)+(gear.Left or 0)+(gear.Right or 0))/3,0,1)
 local brakePressure=clamp((x.Brakes and x.Brakes.BrakePressure) or 0,0,1)
 local leftBrake=clamp((x.Brakes and x.Brakes.LeftPressure) or brakePressure,0,1); local rightBrake=clamp((x.Brakes and x.Brakes.RightPressure) or brakePressure,0,1)
 local thrustAsymmetry=(rightThrust-leftThrust)/math.max(thrust,1)
 local engineOut=leftThrust<thrust*Config.EngineOutThreshold or rightThrust<thrust*Config.EngineOutThreshold
 local rawYawMoment=(rightThrust-leftThrust)*Config.EngineLateralArm; local engineYawMoment=rawYawMoment*Config.EngineYawMomentGain
 x.EngineIntegration.TotalThrust=thrust; x.EngineIntegration.LeftThrust=leftThrust; x.EngineIntegration.RightThrust=rightThrust; x.EngineIntegration.ThrustAsymmetry=clamp(thrustAsymmetry,-1,1); x.EngineIntegration.EngineOut=engineOut and thrust>0; x.EngineIntegration.YawMoment=engineYawMoment
 local wingArea=125.0; local rho=1.225*math.exp(-math.max(x.Altitude or 0,0)/8500)
 local trim=clamp(x.TrimPitch or 0,-8,8); local aoa=clamp((x.Pitch or 0)-trim,-20,30)
 local flapLift=0.52*flap+0.20*flap*flap; local flapDrag=0.025*flap+0.035*flap*flap
 local cl=0.45+0.085*aoa+flapLift; local stallAoA=15; local stallRatio=clamp((math.abs(aoa)-stallAoA)/8,0,1); cl*=1-0.75*stallRatio
 local cd0=0.028+flapDrag+0.02*gearExposed; local cd=cd0+0.045*cl*cl+0.08*stallRatio
 local q=0.5*rho*speedMS*speedMS; local lift=(speedMS<1) and 0 or q*wingArea*cl; local drag=q*wingArea*cd
 local wheelNormal=math.max(weight*math.cos(math.rad(x.Roll or 0)),0); local speedFactor=clamp(speedKts/8,0,1); local leftAnti=1; local rightAnti=1
 if x.Brakes and x.Brakes.AntiSkid~=false and speedKts<8 then leftAnti=speedFactor; rightAnti=speedFactor end
 local wheelBrakeForce=ground and 0.38*wheelNormal*clamp((leftBrake+rightBrake)*0.5,0,1)*((leftAnti+rightAnti)*0.5) or 0
 local reverseForce=ground and reverse*thrust*1.25*clamp(speedKts/35,0,1) or 0
 local reverseRequested=reverse>0 and ground and speedKts>15
 local forwardThrust=thrust*(1-reverse)
 local longitudinalForce=forwardThrust-drag-wheelBrakeForce-reverseForce
 local accel=longitudinalForce/math.max(mass,1)
 if ground and speedKts<25 and throttle<0.05 and brakePressure<0.05 and reverse<0.05 then accel-=0.8 end
 x.Airspeed=clamp(speedKts+accel*1.94384*dt,0,Config.MaxAirspeed)
 if x.Landing then x.Landing.ReverseThrust=reverseRequested end
 if x.Landing then x.Landing.BrakingActive=ground and brakePressure>0.03 and speedKts>3 end
 local qFactor=clamp(speedKts/140,0.12,1.2); local hydraulicAuthority=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0,1)
 local elevator=clamp(s.Elevator or 0,-1,1); local aileron=clamp(s.Aileron or 0,-1,1); local rudder=clamp(s.Rudder or 0,-1,1)
 if ground then local rotationAuthority=clamp((speedKts-55)/40,0.10,1); elevator*=rotationAuthority end
 local pitchControl=elevator*9*qFactor*hydraulicAuthority; local rollControl=aileron*28*qFactor*hydraulicAuthority; local rudderControl=rudder*9*qFactor*hydraulicAuthority
 local trimAoA=2.5+clamp(flap*1.5,0,1.5); local aoaError=aoa-trimAoA; local staticPitchStability=clamp(aoaError*0.30,-7,7)
 local referenceSpeed=clamp(125+flap*20,85,180); local speedError=(speedKts-referenceSpeed)/35; local speedStability=clamp(speedError*0.65,-3.5,3.5)
 local pitchRate=x.PitchRate or 0; local rollRate=x.RollRate or 0; local yawRate=x.YawRate or 0
 if ground then
  local groundYaw=(x.GroundSteering and x.GroundSteering.YawRate) or 0; yawRate=groundYaw; rollRate=approach(rollRate,rollControl,8,dt); pitchRate=approach(pitchRate,pitchControl-staticPitchStability,7,dt); x.Sideslip=approach(x.Sideslip or 0,0,4,dt)
 else
  local bank=clamp(x.Roll or 0,-70,70); local bankRad=math.rad(bank); local turnRate=0; if speedMS>15 then turnRate=math.deg(9.80665*math.tan(bankRad)/speedMS) end; turnRate=clamp(turnRate,-12,12)
  local desiredBeta=clamp(rudder*4.5+turnRate*0.10-rollControl*0.035,-10,10); local beta=x.Sideslip or x.Beta or 0; local betaRate=(desiredBeta-beta)*2.8-beta*0.55-yawRate*0.045; beta=clamp(beta+betaRate*dt,-12,12)
  local weathercock=-beta*0.95; local yawDamping=-yawRate*0.72; local adverseYaw=-aileron*1.4*qFactor*hydraulicAuthority; local targetYawRate=turnRate*0.32+rudderControl+weathercock+yawDamping+adverseYaw+engineYawMoment; yawRate=approach(yawRate,targetYawRate,5.5,dt)
  local rollDamping=-rollRate*0.58*qFactor; rollRate=approach(rollRate,rollControl+rollDamping,7.0,dt); local pitchDamping=-pitchRate*0.35*qFactor; local longitudinalMoment=pitchControl-staticPitchStability-speedStability+pitchDamping; pitchRate=approach(pitchRate,longitudinalMoment,5.5,dt); x.Sideslip=beta; x.Beta=beta; x.TurnCoordination=clamp(1-math.abs(beta)/6,0,1)
 end
 x.PitchRate=pitchRate; x.RollRate=rollRate; x.YawRate=yawRate; x.Yaw=yawRate; x.Pitch=clamp((x.Pitch or 0)+pitchRate*dt,-35,35); x.Roll=clamp((x.Roll or 0)+rollRate*dt,-75,75)
 local groundSteeringRate=ground and ((x.GroundSteering and x.GroundSteering.YawRate) or 0) or 0; x.Heading=wrap((x.Heading or 0)+(ground and groundSteeringRate or yawRate)*dt)
 local flightPathAngle=math.rad((x.Pitch or 0)-aoa); local energyVertical=math.sin(flightPathAngle)*speedMS; local freeVerticalAccel=(lift-weight*math.cos(math.rad(x.Roll or 0)))/math.max(mass,1); local freeVerticalSpeed=(x.VerticalSpeed or 0)+freeVerticalAccel*dt
 if not ground then freeVerticalSpeed=approach(freeVerticalSpeed,energyVertical,18,dt) end
 freeVerticalSpeed*=clamp(1-0.08*math.abs(x.Roll or 0)/45,0.6,1); local liftRatio=lift/math.max(weight,1); local canLiftOff=ground and speedKts>=90 and liftRatio>=0.92 and freeVerticalSpeed>0.5
 if canLiftOff then x.GroundContact=false; x.VerticalSpeed=freeVerticalSpeed else x.VerticalSpeed=clamp(freeVerticalSpeed,-80,80); if x.GroundContact then x.VerticalSpeed=0 end end
 if not x.GroundContact then x.Altitude=clamp((x.Altitude or 0)+x.VerticalSpeed*dt,0,Config.MaxAltitude) end
 x.AirspeedTrue=x.Airspeed/math.sqrt(math.max(rho/1.225,0.15)); x.AoA=aoa; x.StallWarning=math.abs(aoa)>=stallAoA-2 and speedKts>45; x.Lift=lift; x.Drag=drag; x.Mass=mass; x.Weight=weight; x.DynamicPressure=q; x.LoadFactor=lift/math.max(weight,1); x.GLoad=x.LoadFactor; x.AerodynamicDamping={Yaw=0.72*qFactor,Roll=0.58*qFactor,Pitch=0.35*qFactor}
 if ground then x.TurnCoordination=1; x.Beta=x.Sideslip or 0 end
 local forward=CFrame.Angles(math.rad(-(x.Pitch or 0)),math.rad(x.Heading or 0),0).LookVector; x.Velocity=forward*(x.Airspeed*0.514444); x.Position+=x.Velocity*dt
 if x.GroundContact then x.Altitude=0 end
 if x.Airspeed<1 and x.GroundContact then x.Phase="Ground" elseif x.GroundContact then x.Phase="TakeoffOrLanding" else x.Phase="Airborne" end
end
return Physics
