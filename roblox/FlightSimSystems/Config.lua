-- FlightSim shared runtime configuration
return {
	Aircraft = "B737-800",
	Version = "0.4.1",
	TelemetryRate = 20,
	SimulationRate = 60,
	CommandRateLimit = 30,
	MaxThrust = 108000,
	StartN2 = 25,
	MaxAirspeed = 360,
	MaxAltitude = 41000,
	HydraulicMax = 3000,
	-- Game-simulation tuning values for twin-engine asymmetric-thrust dynamics.
	EngineLateralArm = 6.0,
	EngineYawMomentGain = 0.000055,
	EngineOutThreshold = 0.15,
}
