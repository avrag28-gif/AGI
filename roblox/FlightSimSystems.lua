-- FlightSim Systems Coordinator v0.1
-- Bridges the modular Electrical/Fuel/Engine/Hydraulic systems.
-- This module is intentionally separate from FlightSimBootstrap.server.lua during migration.

local Electrical = require(script.Parent.FlightSimElectrical)
local Fuel = require(script.Parent.FlightSimFuel)
local Engine = require(script.Parent.FlightSimEngine)
local Hydraulic = require(script.Parent.FlightSimHydraulic)

local Systems = {}
Systems.__index = Systems

function Systems.new()
	local self = setmetatable({}, Systems)
	self.Electrical = Electrical.new()
	self.Fuel = Fuel.new()
	self.Hydraulic = Hydraulic.new()
	self.Engines = {
		[1] = Engine.new(1),
		[2] = Engine.new(2),
	}
	return self
end

local function copyEngineState(destination, source)
	for key, value in pairs(source) do
		destination[key] = value
	end
end

function Systems:ApplyInputs(aircraftState)
	local e = aircraftState.Electrical
	self.Electrical:SetExternalPower(e.ExternalPower == true)
	self.Electrical:SetAPUGeneratorAvailable(e.APU == true)

	for i = 1, 2 do
		local engine = aircraftState.Engines[i]
		self.Engines[i]:SetStarter(engine.Starter == true)
		self.Engines[i]:SetFuel(engine.FuelOn == true)
		self.Engines[i]:SetIgnition(engine.Ignition == true)
		self.Engines[i]:SetThrottle(aircraftState.Throttle[i] or 0)
	end
end

function Systems:Step(dt, aircraftState)
	assert(type(dt) == "number" and dt >= 0, "Systems:Step requires a non-negative dt")
	self:ApplyInputs(aircraftState)

	-- Initial electrical evaluation supplies starter power. Engine generators
	-- are fed back only after an engine has reached stable running speed.
	self.Electrical:SetEngineGeneratorAvailable(1, false)
	self.Electrical:SetEngineGeneratorAvailable(2, false)
	self.Electrical:Step(dt)

	local bus1 = self.Electrical:GetState().Bus1Powered
	local bus2 = self.Electrical:GetState().Bus2Powered

	self.Engines[1]:Step(dt, bus1)
	self.Engines[2]:Step(dt, bus2)

	self.Electrical:SetEngineGeneratorAvailable(1, self.Engines[1]:GetState().GeneratorAvailable)
	self.Electrical:SetEngineGeneratorAvailable(2, self.Engines[2]:GetState().GeneratorAvailable)
	self.Electrical:Step(0)

	local totalFuelFlow = 0
	for i = 1, 2 do
		local engineState = self.Engines[i]:GetState()
		copyEngineState(aircraftState.Engines[i], engineState)
		totalFuelFlow += engineState.FuelFlow or 0
	end

	-- FuelFlow is normalized by this prototype engine model. The fuel module
	-- owns actual tank depletion, so the coordinator is the only bridge between
	-- combustion demand and tank quantity.
	self.Fuel:Step(dt, totalFuelFlow)

	local fs = self.Fuel:GetState()
	aircraftState.Fuel.Left = fs.Left
	aircraftState.Fuel.Center = fs.Center
	aircraftState.Fuel.Right = fs.Right
	aircraftState.Fuel.Total = fs.Total

	-- Engine operation provides the hydraulic pump source in this first
	-- integration layer. Detailed electric/engine-driven pump modeling comes later.
	local hydraulicPump = self.Engines[1]:GetState().Running or self.Engines[2]:GetState().Running
	self.Hydraulic:SetPump("A", hydraulicPump)
	self.Hydraulic:SetPump("B", hydraulicPump)
	self.Hydraulic:Step(dt)

	local hs = self.Hydraulic:GetState()
	aircraftState.Hydraulic.A = hs.A.Pressure
	aircraftState.Hydraulic.B = hs.B.Pressure

	local es = self.Electrical:GetState()
	aircraftState.Electrical.Battery = es.BatteryAvailable == true
	aircraftState.Electrical.Bus1 = es.Bus1Powered == true
	aircraftState.Electrical.Bus2 = es.Bus2Powered == true

	return aircraftState
end

function Systems:GetSubsystems()
	return {
		Electrical = self.Electrical,
		Fuel = self.Fuel,
		Engines = self.Engines,
		Hydraulic = self.Hydraulic,
	}
end

return Systems
