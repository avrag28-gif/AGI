-- APU/electrical integration regression tests v1.0
-- Guards against APU generator circular-dependency regressions.
local State=require(script.Parent.State)
local APU=require(script.Parent.APU)
local Electrical=require(script.Parent.Electrical)
local Test={}
local function check(condition,message)
	if not condition then error(message,2) end
end

function Test.Run()
	local state=State.new()
	local a=APU.new(state)
	local e=Electrical.new(state)

	state.Electrical.Battery=true
	state.Electrical.APU=true
	a:Step(1.0)
	check(state.APU.RPM>0,"APU failed to spool with battery start power")

	for _=1,4 do
		a:Step(1.0)
	end
	check(state.APU.Running==true,"APU did not reach running state")
	check(state.APU.GeneratorAvailable==true,"APU generator did not become available")

	e:Step(0.1)
	check(state.Electrical.Bus1==true,"APU generator did not energize Bus 1")
	check(state.Electrical.Bus2==true,"APU generator did not energize Bus 2")
	check(state.ElectricalState.APUGenerator==true,"APU generator source not reported")

	return true
end
return Test
