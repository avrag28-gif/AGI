-- FlightSim aircraft model binder v1.0
-- Bridges authoritative simulation State to an explicitly opted-in Roblox aircraft Model.
-- This is a kinematic presentation bridge: it does not replace the aerodynamic solver.
local CollectionService=game:GetService("CollectionService")

local AircraftModelBinder={}
AircraftModelBinder.__index=AircraftModelBinder

local TAG="FlightSimAircraft"
local METERS_TO_STUDS=3.280839895

local function finite(v,d)
	v=tonumber(v)
	return (v and v==v and v~=math.huge and v~=-math.huge) and v or d
end

local function findModel(id)
	for _,model in ipairs(CollectionService:GetTagged(TAG)) do
		if model:IsA("Model") then
			local modelId=model:GetAttribute("FlightSimAircraftId")
			if modelId==id or model.Name==id then return model end
		end
	end
	return nil
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
		end
	end
end

function AircraftModelBinder:StepControls()
	for _,b in pairs(self.bindings) do
		local model=b.model
		local state=b.state and b.state:Get()
		if model and model.Parent and state then
			model:SetAttribute("FlightSimFlap",finite((state.Surface or {}).Flap,0))
			model:SetAttribute("FlightSimGearNose",finite((state.GearPosition or {}).Nose,0))
			model:SetAttribute("FlightSimGearLeft",finite((state.GearPosition or {}).Left,0))
			model:SetAttribute("FlightSimGearRight",finite((state.GearPosition or {}).Right,0))
			model:SetAttribute("FlightSimThrottle1",finite((state.Throttle or {})[1],0))
			model:SetAttribute("FlightSimThrottle2",finite((state.Throttle or {})[2],0))
		end
	end
end

return AircraftModelBinder
