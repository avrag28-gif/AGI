-- FlightSim aerodynamic flight dynamics foundation v0.7
-- Game simulation model; coefficients are tunable approximations, not certified aircraft data.
local Config=require(script.Parent.Config)
local Physics={}; Physics.__index=Physics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
local function approach(v,t,r,dt) local d=t-v; local s=r*dt; if math.abs(d)<=s then return t end return v+(d>0 and s or -s) end

function Physics.new(state) return setmetatable({state=state},Physics) end

function Physics:Step(dt)
	local x=self.state:Get(); local s=x.Surface or {}; local e1=x.Engines[1]; local e2=x.Engines[2]
	local speedKts=math.max(x.Airspeed,0); local speedMS=speedKts*0.514444
	local mass=90000+math.max(0,x.Fuel.Total or 0)*0.8
	local weight=mass*9.80665
	local throttle=(math.clamp(x.Throttle[1] or 0,0,1)+math.clamp(x.Throttle[2] or 0,0,1))*0.5
	local thrust=(e1.Thrust or 0)+(e2.Thrust or 0)
	local flap=math.clamp(s.Flap or 0,0,1)
	local gearDown=((x.GearPosition and x.GearPosition.Nose) or 1)>=0.95
	local brakePressure=math.clamp((x.Brakes and x.Brakes.BrakePressure) or 0,0,1)

	local wingArea=125.0
	local rho=1.225*math.exp(-math.max(x.Altitude,0)/8500)
	local trim=clamp(x.TrimPitch or 0,-8,8)
	local aoa=clamp(x.Pitch-trim,-20,30)
	local cl=0.45+0.085*aoa+flap*0.55
	local stallAoA=15
	local stallRatio=math.clamp((math.abs(aoa)-stallAoA)/8,0,1)
	cl*=1-0.75*stallRatio
	local cd0=0.028+flap*0.025+(gearDown and 0.02 or 0)
	local cd=cd0+0.045*cl*cl+0.08*stallRatio
	local q=0.5*rho*speedMS*speedMS
	local lift=(speedMS<1) and 0 or q*wingArea*cl
	local drag=q*wingArea*cd

	-- Thrust/drag acceleration. Brakes are strongest on the ground.
	local longitudinalForce=thrust-drag-brakePressure*weight*0.015
	local accel=longitudinalForce/math.max(mass,1)
	if x.GroundContact then
		accel-=brakePressure*3.5
		if speedKts<25 and throttle<0.05 then accel-=0.8 end
	end
	x.Airspeed=clamp(speedKts+accel*1.94384*dt,0,Config.MaxAirspeed)

	-- Rotation authority increases with speed. On the runway, the nose is
	-- restrained until rotation speed, preventing an immediate pitch-up.
	local qFactor=clamp(speedKts/140,0.15,1.2)
	local controlAuthority=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0.2,1)
	local elevator=clamp(s.Elevator or 0,-1,1)
	if x.GroundContact and speedKts<75 then elevator*=0.25 end
	local pitchRate=elevator*9*qFactor*controlAuthority
	local rollRate=(s.Aileron or 0)*28*qFactor*controlAuthority
	local yawRate=(s.Rudder or 0)*9*qFactor*controlAuthority

	-- Basic longitudinal stability: high positive AoA naturally drives the
	-- nose down, while trim shifts the neutral point for hands-off flight.
	local stability=clamp((aoa-2.5)*0.22,-4,4)
	if x.GroundContact then stability=0 end
	x.Pitch=clamp(x.Pitch+(pitchRate-stability)*dt,-35,35)
	x.Roll=clamp(x.Roll+rollRate*dt,-75,75)
	x.Yaw=approach(x.Yaw,yawRate*0.5,8,dt)
	x.Heading=wrap(x.Heading+(x.Roll*0.10+x.Yaw)*dt)

	-- Lift-derived vertical motion. Rotation must generate enough lift to leave
	-- the runway; stall reduces lift and increases drag instead of freezing motion.
	local verticalAccel=(lift-weight*math.cos(math.rad(x.Roll)))/math.max(mass,1)
	local verticalSpeed=(x.VerticalSpeed or 0)+verticalAccel*dt
	verticalSpeed*=math.clamp(1-0.08*math.abs(x.Roll)/45,0.6,1)
	if x.GroundContact then verticalSpeed=math.max(verticalSpeed,0) end
	x.VerticalSpeed=clamp(verticalSpeed,-80,80)

	-- Ground contact is released only after positive vertical energy is present;
	-- this avoids bouncing from tiny numerical lift fluctuations.
	if x.GroundContact and x.Altitude<=0.5 and speedKts<90 then
		x.Altitude=0
		x.VerticalSpeed=0
	elseif x.GroundContact and speedKts>=90 and verticalSpeed>1.5 then
		x.GroundContact=false
	end
	if not x.GroundContact then
		x.Altitude=clamp(x.Altitude+x.VerticalSpeed*dt,0,Config.MaxAltitude)
	end

	x.AirspeedTrue=speedKts/math.sqrt(math.max(rho/1.225,0.15))
	x.AoA=aoa
	x.StallWarning=math.abs(aoa)>=stallAoA-2 and speedKts>45
	x.Lift=lift
	x.Drag=drag
	x.Mass=mass
	x.Weight=weight

	-- Simple ground-speed vector for world movement. Later revisions can add
	-- wind, slip/skid and full body-axis integration without changing state API.
	local forward=CFrame.Angles(math.rad(-x.Pitch),math.rad(x.Heading),0).LookVector
	x.Velocity=forward*(x.Airspeed*0.514444)
	x.Position+=x.Velocity*dt

	if x.GroundContact then x.Altitude=0 end
	if x.Airspeed<1 and x.GroundContact then x.Phase="Ground"
	elseif x.GroundContact then x.Phase="TakeoffOrLanding"
	else x.Phase="Airborne" end
end
return Physics
