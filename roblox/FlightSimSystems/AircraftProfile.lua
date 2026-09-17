-- Boeing 737-800 NG baseline aircraft profile v1.2
-- Baseline is explicitly the 737-800 with CFM56-7B26-series engines.
-- Aircraft facts/limits are separated from simulator tuning.
-- Sources: FAA TCDS A16WE; Boeing 737NG airport planning D6-58325-7 Rev C;
-- CFM International CFM56-7B public technical material.
-- This is a simulation configuration, not an FAA-approved AFM/FCOM replacement.

local LB_TO_N=4.4482216152605

return {
	Aircraft={Manufacturer="Boeing",Model="737-800",Family="737 Next Generation",Variant="737-800NG"},
	Engine={Manufacturer="CFM International",Family="CFM56-7B",Model="CFM56-7B26",TakeoffThrustLb=26300,TakeoffThrustN=26300*LB_TO_N,MaxContinuousThrustLb=25900,MaxContinuousThrustN=25900*LB_TO_N,FanDiameterIn=61,FanDiameterM=61*0.0254,N1RedlineRpm=5380,N2RedlineRpm=15183,EGTRedlineC=950,EngineCount=2},
	Limits={VMOKcas=340,MMO=0.82,MaxAltitudeFt=41000},
	Weights={
		OperatingEmptyMassKg=41412,
		MaxZeroFuelMassKg=62731,
		MaxLandingMassKg=66360,
		MaxTakeoffMassKg=79015,
		MaxTaxiMassKg=79242,
		MaxStructuralPayloadKg=21318,
		MaxUsableFuelMassKg=20897,
		ReferenceCGPercentMAC=25,
	},
	Hydraulics={NominalPressurePsi=3000,Systems={"A","B","STANDBY"}},
	Units={Length="SI_m_internal",Mass="kg",Force="N",Altitude="ft",Airspeed="KCAS_or_simulated_kt",Pressure="psi"},
}
