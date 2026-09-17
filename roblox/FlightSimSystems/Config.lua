-- FlightSim shared runtime configuration v0.5
-- Aircraft facts/limits live in AircraftProfile.lua; this file contains runtime rates
-- and compatibility aliases used by existing systems.
local Profile=require(script.Parent.AircraftProfile)

return {
	Aircraft=Profile.Aircraft.Model,
	AircraftVariant=Profile.Aircraft.Variant,
	EngineModel=Profile.Engine.Model,
	Version="0.5.0",
	TelemetryRate=20,
	SimulationRate=60,
	CommandRateLimit=30,

	-- Backward-compatible total takeoff thrust in newtons for the two-engine aircraft.
	MaxThrust=Profile.Engine.TakeoffThrustN*Profile.Engine.EngineCount,
	MaxThrustPerEngine=Profile.Engine.TakeoffThrustN,
	MaxContinuousThrustPerEngine=Profile.Engine.MaxContinuousThrustN,

	StartN2Percent=25,
	StartN2=25,
	MaxAirspeed=Profile.Limits.VMOKcas,
	MaxAltitude=Profile.Limits.MaxAltitudeFt,
	HydraulicMax=Profile.Hydraulics.NominalPressurePsi,

	-- These are simulation integrator parameters, not aircraft-certified values.
	EngineLateralArm=6.0,
	EngineYawMomentGain=0.000055,
	EngineOutThreshold=0.15,
}
