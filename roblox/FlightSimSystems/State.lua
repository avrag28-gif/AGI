-- FlightSim authoritative aircraft state
local State = {}
State.__index = State

local function engineState()
	return {
		N1 = 0,
		N2 = 0,
		EGT = 20,
		OilPressure = 0,
		FuelFlow = 0,
		Thrust = 0,
		Running = false,
		Starter = false,
		FuelOn = false,
		Ignition = false,
		GeneratorAvailable = false,
		StartFailed = false,
	end
end

function State.new()
	return setmetatable({
		Phase = "ColdAndDark",
		Altitude = 0,
		Airspeed = 0,
		Heading = 0,
		Pitch = 0,
		Roll = 0,
		Yaw = 0,
		Position = Vector3.zero,
		Velocity = Vector3.zero,
		Throttle = {[1] = 0, [2] = 0},
		Engines = {[1] = engineState(), [2] = engineState()},
		Electrical = {
			Battery = false,
			ExternalPower = false,
			APU = false,
			Bus1 = false,
			Bus2 = false,
		},
		Hydraulic = {A = 0, B = 0},
		Fuel = {Left = 10000, Center = 10000, Right = 10000, Total = 30000},
		Controls = {Aileron = 0, Elevator = 0, Rudder = 0, Flap = 0, Trim = 0},
		Gear = {Nose = true, Left = true, Right = true},
		Brakes = {Parking = true},
		Avionics = {
			IRS = false,
			FMC = false,
			Radios = false,
			Transponder = false,
			TCAS = false,
		},
		Autopilot = {Enabled = false, TargetAltitude = 0, TargetHeading = 0},
		Failures = {},
	}, State)
end

function State:Get()
	return self
end

return State
