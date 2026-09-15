-- FlightSim flight dynamics foundation v0.4
-- Uses final actuator surfaces; no direct pilot/AP control mutation here.
local Config=require(script.Parent.Config)
local Physics={}; Physics.__index=Physics
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function wrap(v) return (v%360+360)%360 end
function Physics.new(state) return setmetatable({state=state},Physics) end
function Physics:Step(dt)
	local x=self.state:Get(); local s=x.Surface or {}; local e1=x.Engines[1]; local e2=x.Engines[2]
	local thrust=(e1.Thrust or 0)+(e2.Thrust or 0)
	local massFactor=1+((x.Fuel.Total or 0)/30000)*0.18
	local flapDrag=1+(s.Flap or 0)*0.22
	local gearDrag=((x.GearPosition and x.GearPosition.Nose) or 1)<0.95 and 0.18 or 0
	local brakeDrag=(x.BrakePressure or 0)/100*0.8
	local aeroDrag=x.Airspeed*x.Airspeed*0.000055*flapDrag*(1+gearDrag)+brakeDrag
	local accel=(thrust/Config.MaxThrust*48/massFactor)-aeroDrag
	if x.Phase=="Ground" or x.Altitude<8 then accel-=brakeDrag*12 end
	x.Airspeed=clamp(x.Airspeed+accel*dt,0,Config.MaxAirspeed)
	local q=math.max(x.Airspeed,5)/120
	local pitchRate=(s.Elevator or 0)*22/q
	local rollRate=(s.Aileron or 0)*42/q
	local yawRate=(s.Rudder or 0)*18/q + (s.Aileron or 0)*3
	x.Pitch=clamp(x.Pitch+pitchRate*dt,-30,30)
	x.Roll=clamp(x.Roll+rollRate*dt,-70,70)
	x.Yaw=clamp(x.Yaw+yawRate*dt,-30,30)
	x.Heading=wrap(x.Heading+(x.Roll*0.10+x.Yaw)*dt)
	local verticalSpeed=x.Airspeed*0.514444*math.sin(math.rad(x.Pitch))
	if x.Altitude<=8 and x.Pitch<2 then verticalSpeed=0 end
	x.Altitude=clamp(x.Altitude+verticalSpeed*dt*3.281,0,Config.MaxAltitude)
	local speedStuds=x.Airspeed*0.514444
	local forward=CFrame.Angles(math.rad(-x.Pitch),math.rad(x.Heading),0).LookVector
	x.Velocity=forward*speedStuds
	x.Position+=x.Velocity*dt
	if x.Airspeed<1 then x.Phase="Ground" elseif x.Altitude<50 then x.Phase="TakeoffOrLanding" else x.Phase="Airborne" end
end
return Physics
