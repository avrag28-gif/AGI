-- Boeing 737-800 NG baseline aircraft profile v1.1
-- Baseline is explicitly the 737-800 with CFM56-7B26-series engines.
-- This profile separates aircraft facts/limits from simulator tuning.
-- Sources used for this baseline: FAA TCDS A16WE; Boeing 737NG airport planning
-- characteristics D6-58325-7; CFM International CFM56-7B public technical material.
-- This is a simulation configuration, not an FAA-approved AFM/FCOM replacement.

local LB_TO_N=4.4482216152605

return {
	Aircraft={
		Manufacturer="Boeing",
		Model="737-800",
		Family="737 Next Generation",
		Variant="737-800NG",
	},

	Engine={
		Manufacturer="CFM International",
		Family="CFM56-7B",
		Model="CFM56-7B26",
		TakeoffThrustLb=26300,
		TakeoffThrustN=26300*LB_TO_N,
		MaxContinuousThrustLb=25900,
		MaxContinuousThrustN=25900*LB_TO_N,
		FanDiameterIn=61,
		FanDiameterM=61*0.0254,
		N1RedlineRpm=5380,
		N2RedlineRpm=15183,
		EGTRedlineC=950,
		EngineCount=2,
	},

	Limits={
		VMOKcas=340,
		MMO=0.82,
		MaxAltitudeFt=41000,
	},

	Weights={
		-- Boeing 737-800 airport-planning baseline values for the selected profile.
		OperatingEmptyMassKg=41413,
		MaxZeroFuelMassKg=62732,
		MaxLandingMassKg=66361,
		MaxTakeoffMassKg=79016,
		MaxTaxiMassKg=79242,
		-- CG is intentionally a simulator baseline until a full loading station model exists.
		ReferenceCGPercentMAC=25,
	},

	Hydraulics={
		NominalPressurePsi=3000,
		Systems={"A","B","STANDBY"},
	},

	Units={
		Length="SI_m_internal",
		Mass="kg",
		Force="N",
		Altitude="ft",
		Airspeed="KCAS_or_simulated_kt",
		Pressure="psi",
	},
}
