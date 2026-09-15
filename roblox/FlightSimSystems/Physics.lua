-- FlightSim aerodynamic flight dynamics foundation v0.6
-- This is a game simulation model, not certified aircraft engineering data.
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

	-- Approximate aerodynamic coefficients. They are intentionally exposed as
	-- simple parameters so later tuning can be data-driven per aircraft.
	local wingArea=125.0
	local rho=1.225*math.exp(-math.max(x.Altitude,0)/8500)
	local aoa=clamp(x.Pitch-x.TrimPitch, -20, 30)
	local liftSlope=0.085
	local cl=0.45+liftSlope*aoa+flap*0.55
	local stallAoA=15
	local stallRatio=math.clamp((math.abs(aoa)-stallAoA)/8,0,1)
	cl*=1-0.75*stallRatio
	local cd0=0.028+flap*0.025+(gearDown and 0.02 or 0)
	local induced=0.045*cl*cl
	local cd=cd0+induced+0.08*stallRatio
	local q=0.5*rho*speedMS*speedMS
	local lift=q*wingArea*cl
	local drag=q*wingArea*cd

	-- Keep the model controllable at very low speed while allowing stall to
	-- reduce lift and increase drag rather than freezing the aircraft.
	local effectiveLift=lift
	if speedMS<1 then effectiveLift=0 end
	local longitudinalForce=thrust-drag-brakePressure*weight*0.015
	local accel=longitudinalForce/math.max(mass,1)

	-- Ground friction/braking. Parking brake is authoritative through Brakes.
	if x.GroundContact then
		accel-=brakePressure*3.5
		if speedKts<25 and throttle<0.05 then accel-=0.8 end
	end
	x.Airspeed=clamp(speedKts+accel*1.94384*dt,0,Config.MaxAirspeed)

	-- Control response scales with dynamic pressure and hydraulic authority.
	local qFactor=clamp(speedKts/140,0.15,1.2)
	local controlAuthority=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0.2,1)
	local pitchRate=(s.Elevator or 0)*9*qFactor*controlAuthority
	local rollRate=(s.Aileron or 0)*28*qFactor*controlAuthority
	local yawRate=(s.Rudder or 0)*9*qFactor*controlAuthority
	x.Pitch=clamp(x.Pitch+pitchRate*dt,-35,35)
	x.Roll=clamp(x.Roll+rollRate*dt,-75,75)
	x.Yaw=approach(x.Yaw,yawRate*0.5,8,dt)
	x.Heading=wrap(x.Heading+(x.Roll*0.10+x.Yaw)*dt)

	-- Lift-derived vertical acceleration with gravity. This replaces the old
	-- pitch-only climb equation and produces a meaningful stall boundary.
	local verticalAccel=(effectiveLift-weight*math.cos(math.rad(x.Roll)))/math.max(mass,1)
	local verticalSpeed=(x.VerticalSpeed or 0)+verticalAccel*dt
	verticalSpeed*=math.clamp(1-0.08*math.abs(x.Roll)/45,0.6,1)
	if x.GroundContact then verticalSpeed=math.max(verticalSpeed,0) end
	x.VerticalSpeed=clamp(verticalSpeed,-80,80)
	x.Altitude=clamp(x.Altitude+x.VerticalSpeed*dt,0,Config.MaxAltitude)

	x.AirspeedTrue=speedKts/(math.sqrt(math.max(rho/1.225,0.15)))
	x.AoA=aoa
	x.StallWarning=math.abs(aoa)>=stallAoA-2 and speedKts>45
	x.Lift=effectiveLift
	x.Drag=drag
	x.Mass=mass
	x.Weight=weight

	local forward=CFrame.Angles(math.rad(-x.Pitch),math.rad(x.Heading),0).LookVector
	x.Velocity=forward*(x.Airspeed*0.514444)
	x.Position+=x.Velocity*dt

	-- Simple ground-contact hysteresis prevents rapid phase flicker near the runway.
	if x.Altitude<=0.5 then x.GroundContact=true; x.Altitude=0 else x.GroundContact=false end
	if x.Airspeed<1 and x.GroundContact then x.Phase="Ground"
	elseif x.GroundContact then x.Phase="TakeoffOrLanding"
	else x.Phase="Airborne" end
end
return Physics
