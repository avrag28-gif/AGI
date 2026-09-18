-- Boeing 737-800 NG authoritative aircraft state v3.8
-- State is the single shared simulation contract.
-- Weight/CG limits are simulation configuration baselines, not dispatch/AFM data.
local State={}; State.__index=State

local function engineState()
	return {N1=0,N2=0,EGT=20,OilPressure=0,FuelFlow=0,Thrust=0,Running=false,Starter=false,FuelOn=false,Ignition=false,GeneratorAvailable=false,StartFailed=false,Reverse=false,Fire=false,Overheat=false,EEC={Powered=false,Channel="NONE",Fault=false,Alternate=false}}
end
local function hydraulicState() return {Pressure=0,Quantity=0,PumpDemand=0,ElectricPump=false,EnginePump=false,Available=false,Overheat=false} end

function State.new()
	return setmetatable({
		Phase="ColdAndDark",
		Altitude=0,Airspeed=0,Heading=0,Pitch=0,Roll=0,Yaw=0,YawRate=0,RollRate=0,PitchRate=0,
		Sideslip=0,Beta=0,TurnCoordination=0,DynamicPressure=0,LoadFactor=1,GLoad=1,
		AerodynamicDamping={Yaw=0,Roll=0,Pitch=0},
		AeroStability={PitchStabilityFactor=1,RollRestoringRate=0,SideslipRollRate=0,StallControlFactor=1},
		ControlFeel={AileronAuthority=1,ElevatorAuthority=1,RudderAuthority=1,PhysicsRollAuthority=1,PhysicsPitchAuthority=1,PhysicsYawAuthority=1,RudderBlowdownFactor=1},
		EngineIntegration={TotalThrust=0,LeftThrust=0,RightThrust=0,ThrustAsymmetry=0,EngineOut=false,YawMoment=0},
		Position=Vector3.zero,Velocity=Vector3.zero,VerticalSpeed=0,AirspeedTrue=0,AoA=0,
		StallWarning=false,Lift=0,Drag=0,Weight=0,Mass=0,TrimPitch=0,GroundContact=true,
		Throttle={[1]=0,[2]=0},Engines={[1]=engineState(),[2]=engineState()},ReverseThrust=0,
		WeightBalance={OperatingEmptyMassKg=41413,PayloadMassKg=0,FuelMassKg=0,ZeroFuelMassKg=41413,GrossMassKg=41413,CenterOfGravityPercentMAC=25,MaxTakeoffMassKg=79016,MaxLandingMassKg=66361,MaxZeroFuelMassKg=62732,MaxTaxiMassKg=79242,Overweight=false,TakeoffWeightLimited=false,LandingWeightLimited=false},
		Electrical={Battery=false,ExternalPower=false,APU=false,APUGeneratorAvailable=false,Bus1=false,Bus2=false,BusTie=false,StandbyBus=false,LoadShed={NonEssential=false,Display=false,Avionics=false}},
		Hydraulic={A=hydraulicState(),B=hydraulicState(),Standby=hydraulicState()},
		HydraulicDemand={FlightControls=0,LandingGear=0,Brakes=0,Total=0,A=0,B=0,Standby=0},
		-- Cold-and-dark starts with empty usable fuel; dispatch/loading logic populates tanks.
		Fuel={Left=0,Center=0,Right=0,Total=0},
		FuelSystem={LeftQuantity=0,CenterQuantity=0,RightQuantity=0,TotalQuantity=0,LeftPumpSwitch=false,CenterPumpSwitch=false,RightPumpSwitch=false,LeftPump=false,CenterPump=false,RightPump=false,CrossfeedSwitch=false,Crossfeed=false,LeftFeed=false,RightFeed=false,CenterFeed=false,EngineFeed={[1]="AUTO",[2]="AUTO"},EngineFuelSource={[1]="NONE",[2]="NONE"},EngineFuelDemand={[1]=0,[2]=0},EngineFuelDelivered={[1]=0,[2]=0},EngineFuelStarved={[1]=false,[2]=false},EngineFuelAvailable={[1]=false,[2]=false},LowFuel=false,Imbalance=0,FeedPressure=0},
		APU={Running=false,Starter=false,EGT=20,RPM=0,GeneratorAvailable=false,StartFailed=false,Fire=false,Overheat=false},
		BleedAir={Engine1Source=false,Engine2Source=false,APUAvailable=false,APUSource=false,Pack1Available=false,Pack2Available=false,Pack1Output=0,Pack2Output=0,SourceAvailable=false,BleedPressure=0,IsolationValveOpen=false,Pack1Valve=false,Pack2Valve=false},
		Pressurization={CabinAltitudeFt=0,CabinAltitudeRateFpm=0,DifferentialPsi=0,OutflowValve=0.35,Auto=true,ManualCommand=0.35,LandingAltitudeFt=0,Pack1Available=false,Pack2Available=false,BleedSource1=false,BleedSource2=false,SourceAvailable=false,Warning=false,CabinAltitudeWarning=false,DifferentialWarning=false,Dump=false,ReliefActive=false,TakeoffWarning=false},
		Oxygen={PassengerSystemArmed=false,PassengerDeployment=false,CrewOxygenOn=false,CrewPressurePsi=0,LowPressureWarning=false,PortableUnits=0},
		Controls={Aileron=0,Elevator=0,Rudder=0,Flap=0,Trim=0,NoseWheelSteering=0,YawDamper=false,Speedbrake=0,SpoilerLeft=0,SpoilerRight=0},
		Surface={Aileron=0,Elevator=0,Rudder=0,Flap=0,Speedbrake=0,SpoilerLeft=0,SpoilerRight=0},
		FlightControls={PrimaryHydraulicA=false,PrimaryHydraulicB=false,ManualReversion=false,FeelDifferential=0,ElevatorPCU1=false,ElevatorPCU2=false,RudderPCU=false,AileronPCU=false},
		Gear={Nose=true,Left=true,Right=true},GearPosition={Nose=1,Left=1,Right=1},GearStatus={Nose=1,Left=1,Right=1,DownLocked=true,UpLocked=false,Transitioning=false,AlternateExtension=false,Warning=false},
		GroundSteering={Available=true,Command=0,NoseWheelAngle=0,MaxAngle=12,YawRate=0,SpeedAuthority=0,DifferentialBrakeAssist=0},
		Brakes={Parking=true,BrakePressure=0,ToeBrake=0,AntiSkid=true,AntiSkidActive=false,LeftPressure=0,RightPressure=0,LeftWheelSpeed=0,RightWheelSpeed=0,AutobrakeMode="OFF",AutobrakeArmed=false,AutobrakeActive=false,BrakeTemperatureLeft=20,BrakeTemperatureRight=20},
		Avionics={IRS=false,FMC=false,Radios=false,Transponder=false,TCAS=false,WeatherRadar=false,WeatherRadarEnabled=true},
		IRS={Mode="OFF",Left={Mode="OFF",Aligned=false,Latitude=nil,Longitude=nil,Heading=nil,Drift=0},Right={Mode="OFF",Aligned=false,Latitude=nil,Longitude=nil,Heading=nil,Drift=0},AlignmentProgress=0,PositionValid=false,HeadingValid=false},
		Radios={COM1=118,COM2=121.5,NAV1=110,NAV2=112,ADF1=350,ADF2=400},Transponder={Code="2000",Mode="STBY",Ident=false,IdentRemaining=0},
		Navigation={Mode="HDG",ActiveWaypoint=1,Route={},DistanceToWaypoint=0,BearingToWaypoint=0,CrossTrackError=0,RouteComplete=false,CommandHeading=nil,HeadingError=0,CommandAltitude=nil,CommandVerticalSpeed=nil,NAV1Receiver="NONE",NAV1Ident=nil,NAV1Frequency=nil,NAV1Signal=nil,NAV2Receiver="NONE",NAV2Ident=nil,NAV2Frequency=nil,NAV2Signal=nil,ApproachRunway=nil,ILS=nil,VOR=nil,VORStation=nil,VORStationNAV2=nil,VORCourse=0,VORCourseNAV2=0},
		Autopilot={Enabled=false,TargetAltitude=0,TargetHeading=0,TargetVerticalSpeed=0,TargetSpeed=nil,Mode="HDG",CommandBank=0,CommandPitch=0,CommandAileron=0,CommandElevator=0,SpeedError=0,SpeedCommand=nil,ILSLocalizerCaptured=false,ILSGlideSlopeCaptured=false,GoAround=false,GoAroundHeading=nil,GoAroundAltitude=nil,YawDamper=false},
		AutoThrottle={Enabled=false,Active=false,TargetSpeed=nil,SpeedError=0,ThrottleCommand={[1]=0,[2]=0},Mode="OFF",Protection="NONE"},
		VNAV={Mode="OFF",Phase="OFF",TargetAltitude=nil,VerticalSpeed=0,PathError=0,DescentPathAngle=0,CommandVerticalSpeed=nil,ConstraintType=nil,ConstraintAltitude=nil,ConstraintSatisfied=true,TargetSpeed=nil,SpeedConstraintType=nil,SpeedConstraintSatisfied=true,TopOfDescentDistance=nil},
		MCP={Heading=0,Altitude=0,Speed=nil,VerticalSpeed=0,HeadingMode="HDG SEL",AltitudeMode="ALT",SpeedMode="SPD",BankLimit=25,FlightDirector=false},FMC={Page="IDENT",Scratchpad="",Origin=nil,Destination=nil,CruiseAltitude=nil,Route={},Active=false},
		Landing={Phase="GROUND",Touchdown=false,Takeoff=false,Flare=false,Rollout=false,WheelContact=false,TouchdownQuality="NONE",TouchdownEvent=false,BrakingActive=false,ReverseThrust=false,RolloutDistance=0,GoAround=false},FlapSystem={Command=0,Detent=0,Target=0,VFE=250,OverSpeed=false},
		FireProtection={Engines={[1]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true},[2]={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true}},APU={Fire=false,Overheat=false,Warning=false,Detector=0,Armed=true},FireTest=false,MasterWarning=false,MasterFireWarning=false},
		Failures={Fuel={LeftPump=false,CenterPump=false,RightPump=false,Crossfeed=false}},SystemHealth={Electrical=false,HydraulicA=false,HydraulicB=false,Fuel=true},
		Environment={WindDirection=0,WindSpeed=0,TemperatureC=15,PressureHpa=1013.25,VisibilityKm=50,Precipitation=0,Turbulence=0,Icing=0,CloudBaseFt=12000,CeilingFt=20000,Thunderstorm=false,OutsideAirTemperatureC=15,WindU=0,WindV=0,WindW=0,TurbulencePhase=0},
		WeatherEffects={HeadwindKts=0,CrosswindKts=0,GustKts=0,EffectiveAirspeed=0,WindUKts=0,WindVKts=0,TurbulencePitch=0,TurbulenceRoll=0,IcingDragFactor=1,IcingLiftFactor=1,IcingResidual=0,VisibilityFactor=1},
		AntiIce={Engine1=false,Engine2=false,Wing=false,Engine1Available=false,Engine2Available=false,WingAvailable=false,IcingDemand=0,IceProtection=0,EnginePenalty={[1]=1,[2]=1},Warning=false},
		ATC={Facility="GROUND",Phase="COLD",Callsign="FLIGHT",Clearance=nil,PendingReadback=nil,LastMessage="",LastResult="",Squawk="2000",AssignedFrequency=121.7,AssignedRunway=nil,AssignedHeading=nil,AssignedAltitude=nil,AssignedSpeed=nil,ClearanceValid=false,ReadbackValid=false,Sequence=0},ATCDecision={Instruction="NONE",ConflictWith=nil,DistanceM=nil,VerticalSeparationFt=nil},TCAS={Powered=false,Advisories={},ClosestIntruder=nil,ClosestRangeM=nil,HighestLevel="NONE"},
	},State)
end
function State:Get() return self end
return State
