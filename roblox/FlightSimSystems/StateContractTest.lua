-- Authoritative State contract tests v1.0
-- These tests intentionally validate only the state contract/default invariants.
-- Dynamic subsystem behavior belongs to subsystem and integration tests.
local State=require(script.Parent.State)
local Test={}

local function check(condition,message)
	if not condition then error(message,2) end
end

local function finiteNumber(value,name)
	check(type(value)=="number",name.." must be a number")
	check(value==value,name.." must not be NaN")
	check(value~=math.huge and value~=-math.huge,name.." must be finite")
end

function Test.Run()
	local s=State.new()
	check(s.Phase=="ColdAndDark","unexpected initial phase")
	check(#s.Engines==2,"state must contain two engines")
	check(s.Hydraulic.A and s.Hydraulic.B and s.Hydraulic.Standby,"missing hydraulic systems")
	check(s.Electrical.Bus1==false and s.Electrical.Bus2==false,"cold-and-dark electrical state invalid")
	check(s.GearStatus.DownLocked==true,"landing gear must start down-locked")
	check(s.Brakes.Parking==true,"parking brake must start set")
	check(s.Brakes.AntiSkid==true,"anti-skid default must be enabled")
	check(s.Controls.YawDamper==false,"yaw damper default invalid")
	check(s.Oxygen.PassengerSystemArmed==false,"passenger oxygen default invalid")
	check(s.IRS.Left.Aligned==false and s.IRS.Right.Aligned==false,"IRS must start unaligned")
	check(s.Autopilot.Enabled==false and s.AutoThrottle.Enabled==false,"automation must start disabled")
	check(s.FMC.Active==false,"FMC must start inactive")
	check(s.Fuel.Total==0,"cold-and-dark fuel must start empty")
	for i=1,2 do
		local e=s.Engines[i]
		finiteNumber(e.N1,"engine N1")
		finiteNumber(e.N2,"engine N2")
		finiteNumber(e.EGT,"engine EGT")
		finiteNumber(e.Thrust,"engine thrust")
		check(e.EEC.Powered==false,"EEC must start unpowered")
	end
	return true
end

return Test
