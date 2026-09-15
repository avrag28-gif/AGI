-- FlightSim flight dynamics foundation v0.3
local Config = require(script.Parent.Config)
local Physics = {}
Physics.__index = Physics

function Physics.new(state)
	return setmetatable({state = state}, Physics)
end

function Physics:Step(dt)
	local x = self.state:Get()
	local c = x.Controls

	if x.Autopilot.Enabled then
		local headingError = ((x.Autopilot.TargetHeading - x.Heading + 540) % 360) - 180
		c.Aileron = math.clamp(headingError * 0.015, -0.35, 0.35)
		local altitudeError = x.Autopilot.TargetAltitude - x.Altitude
		c.Elevator = math.clamp(altitudeError * 0.0008, -0.18, 0.18)
	end

	local thrust = x.Engines[1].Thrust + x.Engines[2].Thrust
	local throttle = (x.Throttle[1] + x.Throttle[2]) * 0.5
	local effectiveThrust = thrust * (0.35 + 0.65 * throttle)
	local acceleration = effectiveThrust / Config.MaxThrust * 42

	x.Airspeed = math.clamp(x.Airspeed + (acceleration - x.Airspeed * 0.020) * dt, 0, Config.MaxAirspeed)
	x.Pitch = math.clamp(x.Pitch + c.Elevator * 18 * dt, -25, 25)
	x.Roll = math.clamp(x.Roll + c.Aileron * 35 * dt, -60, 60)
	x.Yaw = math.clamp(x.Yaw + c.Rudder * 20 * dt, -25, 25)
	x.Heading = (x.Heading + x.Yaw * dt) % 360

	local verticalSpeed = x.Airspeed * 0.514444 * math.sin(math.rad(x.Pitch))
	x.Altitude = math.clamp(x.Altitude + verticalSpeed * dt * 3.281, 0, Config.MaxAltitude)

	local speedStuds = x.Airspeed * 0.514444
	x.Velocity = CFrame.Angles(0, math.rad(x.Heading), 0).LookVector * speedStuds
	x.Position += x.Velocity * dt

	if x.Airspeed < 1 then
		x.Phase = "Ground"
	elseif x.Altitude < 50 then
		x.Phase = "TakeoffOrLanding"
	else
		x.Phase = "Airborne"
	end
end

return Physics
