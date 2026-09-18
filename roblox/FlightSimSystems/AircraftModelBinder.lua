-- FlightSim aircraft model binder v1.0
-- Bridges authoritative simulation State to an explicitly opted-in Roblox aircraft Model.
-- This is a kinematic presentation bridge: it does not replace the aerodynamic solver.
local CollectionService=game:GetService("CollectionService")

local AircraftModelBinder={}
AircraftModelBinder.__index=AircraftModelBinder

local function findMotor(model,names)
	for _,name in ipairs(names) do
		local obj=model:FindFirstChild(name,true)
		if obj and obj:IsA("Motor6D") then return obj end
	end
	return nil
end

local function finite(v,d)
	v=tonumber(v)
	return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end



local function attrNumber(model,names,default)
	for _,name in ipairs(names) do
		local v=model:GetAttribute(name)
		if typeof(v)=="number" then return v end
	end
	return default
end

local TAG="FlightSimAircraft"
local METERS_TO_STUDS=3.280839895

local function findModel(id)
	for _,model in ipairs(CollectionService:GetTagged(TAG)) do
		if model:IsA("Model") then
			local modelId=model:GetAttribute("FlightSimAircraftId")
			if modelId==id or model.Name==id then return model end
		end
	end
	return nil
end

local function animateMotor(motor,angleDeg,axis,alpha)
	if not motor then return end
	local r=math.rad(angleDeg)
	local target
	if axis=="Y" then target=CFrame.Angles(0,r,0)
	elseif axis=="Z" then target=CFrame.Angles(0,0,r)
	else target=CFrame.Angles(r,0,0) end
	motor.Transform=motor.Transform:Lerp(target,alpha)
end

local function setKinematic(model,enabled)
	if not enabled then return end
	for _,obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored=true
			obj.CanTouch=false
			obj.CanQuery=true
		end
	end
end

function AircraftModelBinder.new()
	return setmetatable({bindings={},pending={}},AircraftModelBinder)
end

function AircraftModelBinder:Bind(id,state)
	if not id or not state then return false,"invalid binding" end
	local model=findModel(id)
	if not model then
		self.pending[id]=state
		return false,"aircraft model not found; waiting for tagged model"
	end
	local kinematic=model:GetAttribute("FlightSimKinematic")
	if kinematic==nil then kinematic=true end
	setKinematic(model,kinematic==true)
	self.bindings[id]={model=model,state=state,kinematic=kinematic==true}
	self.pending[id]=nil
	return true
end

function AircraftModelBinder:Unbind(id)
	self.bindings[id]=nil
	self.pending[id]=nil
end

function AircraftModelBinder:Refresh()
	for id,state in pairs(self.pending) do
		self:Bind(id,state)
	end
end

function AircraftModelBinder:Step()
	for id,b in pairs(self.bindings) do
		local model=b.model
		local state=b.state and b.state:Get()
		if not model or not model.Parent or not state then
			self.bindings[id]=nil
		else
			local p=state.Position or Vector3.zero
			local px=finite(p.X,0)*METERS_TO_STUDS
			local py=finite(p.Y,0)*METERS_TO_STUDS
			local pz=finite(p.Z,0)*METERS_TO_STUDS
			local heading=math.rad(finite(state.Heading,0))
			local pitch=math.rad(finite(state.Pitch,0))
			local roll=math.rad(finite(state.Roll,0))
			-- The simulation convention is heading 0 = +Z, 90 = +X.
			-- lookAt uses -Z as the model's forward axis, so this preserves
			-- the simulation convention without depending on PrimaryPart.
			local forward=Vector3.new(math.sin(heading)*math.cos(pitch),math.sin(pitch),math.cos(heading)*math.cos(pitch))
			local target=Vector3.new(px,py,pz)+forward
			local cf=CFrame.lookAt(Vector3.new(px,py,pz),target,Vector3.yAxis)
			-- Roll is applied around the aircraft's local forward axis.
			cf=cf*CFrame.Angles(0,0,roll)
			if b.kinematic then model:PivotTo(cf) end
			model:SetAttribute("FlightSimHeading",finite(state.Heading,0))
			model:SetAttribute("FlightSimPitch",finite(state.Pitch,0))
			model:SetAttribute("FlightSimRoll",finite(state.Roll,0))
			model:SetAttribute("FlightSimAltitudeFt",finite(state.Altitude,0))
			model:SetAttribute("FlightSimAirspeedKt",finite(state.Airspeed,0))
			model:SetAttribute("FlightSimGroundContact",state.GroundContact==true)
			local elec=state.Electrical or {}
			local hyd=state.Hydraulic or {}
			local gearStatus=state.GearStatus or {}
			local ap=state.Autopilot or {}
			local at=state.AutoThrottle or {}
			local brakes=state.Brakes or {}
			local annunciation=state.Annunciation or {}
			model:SetAttribute("FlightSimBattery",elec.Battery==true)
			model:SetAttribute("FlightSimExternalPower",elec.ExternalPower==true)
			model:SetAttribute("FlightSimAPUGenerator",elec.APUGeneratorAvailable==true)
			model:SetAttribute("FlightSimBus1",elec.Bus1==true)
			model:SetAttribute("FlightSimBus2",elec.Bus2==true)
			model:SetAttribute("FlightSimHydraulicAPressure",finite(hyd.A and hyd.A.Pressure,0))
			model:SetAttribute("FlightSimHydraulicBPressure",finite(hyd.B and hyd.B.Pressure,0))
			model:SetAttribute("FlightSimHydraulicStandbyPressure",finite(hyd.Standby and hyd.Standby.Pressure,0))
			model:SetAttribute("FlightSimGearDownLocked",gearStatus.DownLocked==true)
			model:SetAttribute("FlightSimGearUpLocked",gearStatus.UpLocked==true)
			model:SetAttribute("FlightSimGearWarning",gearStatus.Warning==true)
			model:SetAttribute("FlightSimBrakePressure",finite(brakes.BrakePressure,0))
			model:SetAttribute("FlightSimParkingBrake",brakes.Parking==true)
			model:SetAttribute("FlightSimAPEnabled",ap.Enabled==true)
			model:SetAttribute("FlightSimAPMode",tostring(ap.Mode or "OFF"))
			model:SetAttribute("FlightSimAPTargetAltitude",finite(ap.TargetAltitude,0))
			local mcp=state.MCP or {}
			model:SetAttribute("FlightSimMCPHeading",finite(mcp.Heading,0))
			model:SetAttribute("FlightSimMCPAltitude",finite(mcp.Altitude,0))
			model:SetAttribute("FlightSimMCPSpeed",finite(mcp.Speed,0))
			model:SetAttribute("FlightSimMCPVerticalSpeed",finite(mcp.VerticalSpeed,0))
			model:SetAttribute("FlightSimMCPHeadingMode",tostring(mcp.HeadingMode or "OFF"))
			model:SetAttribute("FlightSimMCPAltitudeMode",tostring(mcp.AltitudeMode or "OFF"))
			model:SetAttribute("FlightSimMCPVerticalSpeedMode",tostring(mcp.VerticalSpeedMode or "OFF"))
			model:SetAttribute("FlightSimMCPFlightDirector",mcp.FlightDirector==true)
			model:SetAttribute("FlightSimATEnabled",at.Enabled==true)
			model:SetAttribute("FlightSimATMode",tostring(at.Mode or "OFF"))
			model:SetAttribute("FlightSimATProtection",tostring(at.Protection or "NONE"))
			model:SetAttribute("FlightSimMasterWarning",(annunciation.MasterWarning or false)==true)
			model:SetAttribute("FlightSimMasterCaution",(annunciation.MasterCaution or false)==true)
			model:SetAttribute("FlightSimAnnunciationFire",(annunciation.Fire or false)==true)
			model:SetAttribute("FlightSimAnnunciationStall",(annunciation.Stall or false)==true)
			model:SetAttribute("FlightSimAnnunciationGearUnsafe",(annunciation.GearUnsafe or false)==true)
			model:SetAttribute("FlightSimAnnunciationFlapOverspeed",(annunciation.FlapOverspeed or false)==true)
			model:SetAttribute("FlightSimAnnunciationHydraulicLow",(annunciation.HydraulicLow or false)==true)
			model:SetAttribute("FlightSimAnnunciationElectricalLoss",(annunciation.ElectricalLoss or false)==true)
			model:SetAttribute("FlightSimAnnunciationEngineOut",(annunciation.EngineOut or false)==true)
			model:SetAttribute("FlightSimAnnunciationTrafficTA",(annunciation.TrafficTA or false)==true)
			model:SetAttribute("FlightSimAnnunciationTrafficRA",(annunciation.TrafficRA or false)==true)
			model:SetAttribute("FlightSimAnnunciationMessages",table.concat(annunciation.Messages or {}," | "))
		end
	end
end

function AircraftModelBinder:StepControls()
	for _,b in pairs(self.bindings) do
		local model=b.model
		local state=b.state and b.state:Get()
		if model and model.Parent and state then
			local surface=state.Surface or {}
			local flap=finite(surface.Flap,0)
			local elevator=finite(surface.Elevator,0)
			local aileron=finite(surface.Aileron,0)
			local rudder=finite(surface.Rudder,0)
			local speedbrake=finite(surface.Speedbrake,finite(surface.Spoilers,0))
			local gear=state.GearPosition or {}
			local throttle=state.Throttle or {}
			model:SetAttribute("FlightSimFlap",finite((state.Surface or {}).Flap,0))
			local flapSystem=state.FlapSystem or {}
			local trimState=state.TrimState or {}
			local steering=state.GroundSteering or {}
			local landing=state.Landing or {}
			model:SetAttribute("FlightSimFlapDetent",finite(flapSystem.Detent,0))
			model:SetAttribute("FlightSimFlapCommandDetent",finite(flapSystem.Command,0))
			model:SetAttribute("FlightSimFlapVFE",finite(flapSystem.VFE,250))
			model:SetAttribute("FlightSimFlapOverspeed",flapSystem.OverSpeed==true)
			model:SetAttribute("FlightSimTrimPitch",finite(state.TrimPitch,0))
			model:SetAttribute("FlightSimTrimCommand",finite(trimState.Command,0))
			model:SetAttribute("FlightSimNoseWheelAngle",finite(steering.NoseWheelAngle,0))
			model:SetAttribute("FlightSimGearDownLocked",(state.GearStatus or {}).DownLocked==true)
			model:SetAttribute("FlightSimGearUpLocked",(state.GearStatus or {}).UpLocked==true)
			model:SetAttribute("FlightSimGearTransitioning",(state.GearStatus or {}).Transitioning==true)
			model:SetAttribute("FlightSimLandingPhase",tostring(landing.Phase or "GROUND"))
			model:SetAttribute("FlightSimGearNose",finite(gear.Nose,0))
			model:SetAttribute("FlightSimGearLeft",finite(gear.Left,0))
			model:SetAttribute("FlightSimGearRight",finite(gear.Right,0))
			model:SetAttribute("FlightSimThrottle1",finite(throttle[1],0))
			model:SetAttribute("FlightSimThrottle2",finite(throttle[2],0))
			model:SetAttribute("FlightSimEngine1N1",finite((state.Engines[1] or {}).N1,0))
			model:SetAttribute("FlightSimEngine2N1",finite((state.Engines[2] or {}).N1,0))
			model:SetAttribute("FlightSimEngine1N2",finite((state.Engines[1] or {}).N2,0))
			model:SetAttribute("FlightSimEngine2N2",finite((state.Engines[2] or {}).N2,0))
			model:SetAttribute("FlightSimEngine1EGT",finite((state.Engines[1] or {}).EGT,0))
			model:SetAttribute("FlightSimEngine2EGT",finite((state.Engines[2] or {}).EGT,0))
			model:SetAttribute("FlightSimEngine1Running",(state.Engines[1] or {}).Running==true)
			model:SetAttribute("FlightSimEngine2Running",(state.Engines[2] or {}).Running==true)
			local e1=findMotor(model,{"Engine1FanMotor","LeftFanMotor","EngineLeftFanMotor"})
			local e2=findMotor(model,{"Engine2FanMotor","RightFanMotor","EngineRightFanMotor"})
			animateMotor(e1,finite((state.Engines[1] or {}).N1,0)*12,"Z",0.35)
			animateMotor(e2,finite((state.Engines[2] or {}).N1,0)*12,"Z",0.35)
			model:SetAttribute("FlightSimAileron",aileron)
			model:SetAttribute("FlightSimElevator",elevator)
			model:SetAttribute("FlightSimRudder",rudder)
			model:SetAttribute("FlightSimSpeedbrake",speedbrake)

			-- Optional mechanical animation contract. A model can provide Motor6D
			-- names without requiring them; absent motors are simply ignored.
			local alpha=0.45
			animateMotor(findMotor(model,{"LeftAileronMotor","AileronLeftMotor"}),aileron*18,"X",alpha)
			animateMotor(findMotor(model,{"RightAileronMotor","AileronRightMotor"}),aileron*-18,"X",alpha)
			animateMotor(findMotor(model,{"ElevatorMotor","ElevatorLeftMotor"}),elevator*-15,"X",alpha)
			animateMotor(findMotor(model,{"RudderMotor"}),rudder*20,"Y",alpha)
			animateMotor(findMotor(model,{"FlapMotor","FlapsMotor"}),flap*30,"X",alpha)
			animateMotor(findMotor(model,{"SpeedbrakeMotor","SpoilerMotor"}),speedbrake*35,"X",alpha)
			local gearAngle=attrNumber(model,{"GearAnimationAngle"},90)
			animateMotor(findMotor(model,{"NoseGearMotor","GearNoseMotor"}),finite(gear.Nose,0)*gearAngle,"X",alpha)
			animateMotor(findMotor(model,{"LeftGearMotor","GearLeftMotor"}),finite(gear.Left,0)*gearAngle,"X",alpha)
			animateMotor(findMotor(model,{"RightGearMotor","GearRightMotor"}),finite(gear.Right,0)*gearAngle,"X",alpha)
			-- Optional throttle/flap-handle animation for physical cockpit models.
			local throttle1=finite(throttle[1],0)
			local throttle2=finite(throttle[2],0)
			local throttleAngle=attrNumber(model,{"ThrottleAnimationAngle"},35)
			animateMotor(findMotor(model,{"Throttle1Motor","Engine1ThrottleMotor","LeftThrottleMotor"}),throttle1*throttleAngle,"X",alpha)
			animateMotor(findMotor(model,{"Throttle2Motor","Engine2ThrottleMotor","RightThrottleMotor"}),throttle2*throttleAngle,"X",alpha)
			local reverse=state.ReverseThrust or {}
			model:SetAttribute("FlightSimReverse1",finite(reverse[1],0))
			model:SetAttribute("FlightSimReverse2",finite(reverse[2],0))
			animateMotor(findMotor(model,{"FlapLeverMotor","FlapsLeverMotor"}),flap*35,"X",alpha)
			animateMotor(findMotor(model,{"SpeedbrakeLeverMotor","SpeedbrakeHandleMotor"}),speedbrake*30,"X",alpha)
		end
	end
end

return AircraftModelBinder
