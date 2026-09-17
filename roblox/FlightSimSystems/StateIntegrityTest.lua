--!strict
-- Regression tests for the authoritative aircraft state contract.
local State=require(script.Parent.State)
local StateIntegrity=require(script.Parent.StateIntegrity)

local Test={}
local function check(condition:boolean,message:string)
	if not condition then error(message,2) end
end

local function hasCode(errors,code:string):boolean
	for _,item in ipairs(errors) do
		if item.Code==code then return true end
	end
	return false
end

function Test.Run():boolean
	local state=State.new()
	local monitor=StateIntegrity.new()
	local ok,errors=monitor:Check(state)
	check(ok,"fresh State must satisfy StateIntegrity")
	check(#errors==0,"fresh State produced unexpected integrity errors")

	state.Altitude=70000
	ok,errors=monitor:Check(state)
	check(not ok,"invalid altitude must be rejected")
	check(hasCode(errors,"ALTITUDE_INVALID"),"missing ALTITUDE_INVALID")

	state.Altitude=0
	state.Hydraulic.A.Pressure=3000
	state.Hydraulic.B.Pressure=3000
	state.Hydraulic.Standby.Pressure=0
	ok,errors=monitor:Check(state)
	check(ok,"structured hydraulic state must validate")
	check(#errors==0,"structured hydraulic state produced unexpected errors")

	state.Engines[1].N1=150
	ok,errors=monitor:Check(state)
	check(not ok,"invalid engine N1 must be rejected")
	check(hasCode(errors,"ENGINE_N1_INVALID"),"missing ENGINE_N1_INVALID")

	return true
end

return Test
