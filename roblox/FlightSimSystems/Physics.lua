-- FlightSim aerodynamic / ground dynamics foundation v3.5
-- Game-simulation model; coefficients are tunable approximations, not certified aircraft data.
-- State units: Airspeed=kt, Altitude=ft, VerticalSpeed=ft/min, Position/Velocity=game-space meters.
local Config=require(script.Parent.Config)
local WeightBalance=require(script.Parent.WeightBalance)
local FlightEnvelope=require(script.Parent.FlightEnvelope)
local Atmosphere=require(script.Parent.Atmosphere)
local Physics={}; Physics.__index=Physics
local FT_TO_M=0.3048
local FPM_TO_MS=FT_TO_M/60
local MS_TO_FPM=1/FPM_TO_MS
local G=9.80665
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end
local function finite(v,d) v=tonumber(v); return (v and v==v and v~=math.huge and v~=-math.huge) and v or d end
function Physics.new(state) return setmetatable({state=state},Physics) end
function Physics:Step(dt)
 local x=self.state:Get(); local s=x.Surface or {}; local e1=x.Engines[1] or {}; local e2=x.Engines[2] or {}; dt=clamp(finite(dt,1/60),0,0.25)
 local speedKts=math.max(finite(x.Airspeed,0),0); local speedMS=speedKts*0.514444
 local weather=x.WeatherEffects or {}; local effectiveAirspeed=clamp(finite(weather.EffectiveAirspeed,speedKts),0,500); local aeroSpeedMS=effectiveAirspeed*0.514444
 local altitudeFt=math.max(finite(x.Altitude,0),0)
 local ambientTempC=finite((x.Environment or {}).TemperatureC,Atmosphere.ISATemperatureC(altitudeFt))
 local atm=Atmosphere.State(altitudeFt,ambientTempC); local rho=atm.DensityKgM3; x.Mach=clamp(aeroSpeedMS/math.max(atm.SpeedOfSoundMS,1),0,0.95); x.DynamicTemperatureC=ambientTempC; x.AirDensityKgM3=rho
 local icingDrag=clamp(finite(weather.IcingDragFactor,1),1,1.12); local icingLift=clamp(finite(weather.IcingLiftFactor,1),0.88,1); local crosswind=clamp(finite(weather.CrosswindKts,0),-80,80); local turbP=clamp(finite(weather.TurbulencePitch,0),-1.5,1.5); local turbR=clamp(finite(weather.TurbulenceRoll,0),-1.5,1.5)
 local weightData=WeightBalance.Step(x); local mass=math.max(weightData.GrossMassKg,1); local weight=mass*G
 local throttle=(clamp(finite((x.Throttle or {})[1],0),0,1)+clamp(finite((x.Throttle or {})[2],0),0,1))*0.5
 local lt=math.max(finite(e1.Thrust,0),0); local rt=math.max(finite(e2.Thrust,0),0); local thrust=lt+rt; local ground=x.GroundContact==true; local flap=clamp(finite(s.Flap,0),0,1); local gear=x.GearPosition or {}; local gearExposed=clamp((finite(gear.Nose,0)+finite(gear.Left,0)+finite(gear.Right,0))/3,0,1)
 local brakes=x.Brakes or {}; local brake=clamp(finite(brakes.BrakePressure,0),0,1); local lp=clamp(finite(brakes.LeftPressure,brake),0,1); local rp=clamp(finite(brakes.RightPressure,brake),0,1); local reverse=ground and clamp(finite(x.ReverseThrust,0),0,1) or 0
 local asym=(rt-lt)/math.max(thrust,1); x.EngineIntegration.TotalThrust=thrust; x.EngineIntegration.LeftThrust=lt; x.EngineIntegration.RightThrust=rt; x.EngineIntegration.ThrustAsymmetry=clamp(asym,-1,1); x.EngineIntegration.EngineOut=(e1.Running==true and e2.Running~=true) or (e2.Running==true and e1.Running~=true)
 local wingArea=125; local trim=clamp(finite(x.TrimPitch,0),-8,8); local pitchAngle=finite(x.Pitch,0)
 -- Control-surface effects are applied through the already hydraulic-limited Surface state.
 local controlLoad=clamp(math.abs(finite(s.Elevator,0))+math.abs(finite(s.Aileron,0))*0.35+math.abs(finite(s.Rudder,0))*0.15,0,1.5)
 local aoa=clamp(2.5+0.15*(pitchAngle-trim)+0.20*flap+0.75*finite(s.Elevator,0),-20,30)
 local flapLift=0.52*flap+0.20*flap*flap; local flapDrag=0.025*flap+0.035*flap*flap
 local cl=(0.45+0.085*aoa+flapLift)*icingLift
 local stall=clamp((math.abs(aoa)-15)/8,0,1); cl*=1-0.75*stall
 local cd=(0.028+flapDrag+0.02*gearExposed+0.045*cl*cl+0.08*stall+0.012*controlLoad)*icingDrag
 local q=0.5*rho*aeroSpeedMS*aeroSpeedMS; local lift=(aeroSpeedMS<1) and 0 or q*wingArea*cl; local drag=q*wingArea*cd
 local bank=clamp(finite(x.Roll,0),-70,70); local fpa=math.rad(pitchAngle-aoa)
 local wheelNormal=math.max(weight*math.cos(math.rad(bank)),0); local wheelBrake=ground and 0.38*wheelNormal*clamp((lp+rp)*0.5,0,1) or 0
 local reverseForce=ground and reverse*thrust*1.25*clamp(speedKts/35,0,1) or 0
 local gravityAlongPath=ground and 0 or weight*math.sin(fpa)
 local longitudinal=thrust-drag-wheelBrake-reverseForce-gravityAlongPath
 if ground and speedKts<25 and throttle<0.05 and brake<0.05 and reverse<0.05 then longitudinal-=0.8*mass end
 local accel=longitudinal/math.max(mass,1); x.Airspeed=clamp(speedKts+accel*1.94384*dt,0,Config.MaxAirspeed); x.DynamicPressure=q; x.Lift=lift; x.Drag=drag; x.LoadFactor=lift/math.max(weight,1); x.GLoad=x.LoadFactor; x.AoA=aoa
 local envelope=FlightEnvelope.Step(x)
 x.StallWarning=envelope.StallWarning or math.abs(aoa)>=13 and speedKts>45; x.StallActive=envelope.StallActive or stall>=1; x.OverspeedWarning=envelope.Overspeed
 -- High-AoA/stall reduces the effectiveness of all aerodynamic control moments.
 -- The surfaces remain physically commanded, but their aerodynamic authority is degraded.
 local stallControlFactor=1-0.70*stall
 local qf=clamp(effectiveAirspeed/140,0.12,1.2)*stallControlFactor
 local ail=clamp(finite(s.Aileron,0),-1,1); local ele=clamp(finite(s.Elevator,0),-1,1); local rud=clamp(finite(s.Rudder,0),-1,1)
 local pCtrl=ele*9*qf; local rCtrl=ail*28*qf; local yCtrl=rud*9*qf
 local pr=finite(x.PitchRate,0); local rr=finite(x.RollRate,0); local yr=finite(x.YawRate,0)
 if ground then local auth=clamp((speedKts-55)/40,0.1,1); pr=approach(pr,pCtrl*auth+0.05*turbP,7,dt); rr=approach(rr,rCtrl*clamp(speedKts/45,0,1)+0.05*turbR,8,dt); yr=finite((x.GroundSteering or {}).YawRate,0); x.Sideslip=approach(finite(x.Sideslip,0),clamp(crosswind*0.03,-3,3),4,dt)
 else
  local turn=0; if speedMS>15 then turn=math.deg(G*math.tan(math.rad(bank))/speedMS) end; turn=clamp(turn,-12,12)
  local beta=finite(x.Sideslip,finite(x.Beta,0)); local windBeta=clamp(crosswind/math.max(effectiveAirspeed,60)*57.2958,-5,5); local desired=clamp(rud*4.5+turn*.1-rCtrl*.035+windBeta*.12,-10,10)
  beta=clamp(beta+((desired-beta)*2.8-beta*.55-yr*.045)*dt,-12,12)
  -- Engine-out yaw is derived from normalized thrust asymmetry. The previous
  -- implementation added a force-like quantity directly to deg/s, which could
  -- create unrealistically large yaw rates. Keep the effect bounded and speed-aware.
  local asymmetricYaw=clamp(asym*3.5*qf,-5,5)
  yr=approach(yr,turn*.32+yCtrl-beta*.95-yr*.72-ail*1.4*qf+asymmetricYaw+clamp(crosswind*.015,-.9,.9),5.5,dt)
  rr=approach(rr,rCtrl-rr*.58*qf+.25*turbR,7,dt)
  pr=approach(pr,pCtrl-(aoa-(2.5+clamp(flap*1.5,0,1.5)))*.30-clamp(((speedKts-(125+flap*20))/35)*.65,-3.5,3.5)-pr*.35*qf+.25*turbP,5.5,dt)
  x.Sideslip=beta; x.Beta=beta; x.TurnCoordination=clamp(1-math.abs(beta)/6,0,1)
 end
 x.EngineIntegration.YawRateContribution=ground and 0 or clamp(asym*3.5*qf,-5,5)
 x.EngineIntegration.StallControlFactor=stallControlFactor
 x.PitchRate=pr; x.RollRate=rr; x.YawRate=yr; x.Yaw=yr; x.Pitch=clamp(pitchAngle+pr*dt,-35,35); x.Roll=clamp(bank+rr*dt,-75,75); x.Heading=wrap(finite(x.Heading,0)+(ground and finite((x.GroundSteering or {}).YawRate,0) or yr)*dt)
 local targetVSMS=math.sin(fpa)*aeroSpeedMS; local vsFpm=finite(x.VerticalSpeed,0); local vsMS=vsFpm*FPM_TO_MS
 local verticalForce=(lift*math.cos(math.rad(bank)))+thrust*math.sin(fpa)-weight
 local verticalAccel=clamp(verticalForce/math.max(mass,1),-8,8)
 vsMS+=verticalAccel*dt
 if not ground then vsMS=approach(vsMS,targetVSMS,12,dt) end
 vsMS*=clamp(1-.08*math.abs(x.Roll)/45,.6,1)
 local liftRatio=lift/math.max(weight,1)
 local liftoff=ground and speedKts>=90 and liftRatio>=.92 and vsMS>0.5
 if liftoff then x.GroundContact=false elseif ground then vsMS=0 end
 x.VerticalSpeed=clamp(vsMS*MS_TO_FPM,-8000,8000)
 local altitude=altitudeFt; if x.GroundContact then altitude=0 else altitude=clamp(altitude+x.VerticalSpeed*dt/60,0,Config.MaxAltitude) end
 local gearDown=(x.GearStatus and x.GearStatus.DownLocked==true) or ((finite(gear.Nose,0)+finite(gear.Left,0)+finite(gear.Right,0))/3>=0.98); local touchdownCandidate=(not x.GroundContact) and gearDown and altitude<=2.0 and x.VerticalSpeed<=0
 if touchdownCandidate then x.GroundContact=true; altitude=0; x.VerticalSpeed=0; vsMS=0 end
 x.Altitude=altitude
 local yMeters=altitude*FT_TO_M; local forward=CFrame.Angles(math.rad(-x.Pitch),math.rad(x.Heading),0).LookVector; local wu=finite(weather.WindUKts,0); local wv=finite(weather.WindVKts,0); local verticalMS=x.GroundContact and 0 or x.VerticalSpeed*FPM_TO_MS; x.Velocity=forward*(x.Airspeed*.514444)+Vector3.new(wu*.514444,verticalMS,wv*.514444); x.Position+=x.Velocity*dt; if x.GroundContact then x.Position=Vector3.new(x.Position.X,0,x.Position.Z) else x.Position=Vector3.new(x.Position.X,yMeters,x.Position.Z) end; x.Phase=x.GroundContact and (x.Airspeed<1 and "Ground" or "TakeoffOrLanding") or "Airborne"
end
return Physics
