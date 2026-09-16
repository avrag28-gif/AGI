-- FlightSim ATC traffic contract tests v0.1
local ATCTraffic=require(script.Parent.ATCTraffic)
local TrafficTest={}
local function check(condition,message) if not condition then error(message,2) end end
function TrafficTest.Run()
	local t=ATCTraffic.new()
	check(t:RegisterRunway("27")==true,"runway registration failed")
	local ok,r=t:Reserve("27","AC1","FS1001","TAKEOFF")
	check(ok and r.State=="RESERVED","takeoff reservation failed")
	local allowed,reason=t:CanIssue("27","AC2","LANDING")
	check(not allowed and reason=="runway_reserved","conflicting landing was allowed")
	check(t:SetOccupied("27","AC1"),"occupancy transition failed")
	allowed,reason=t:CanIssue("27","AC2","TAKEOFF")
	check(not allowed and reason=="runway_occupied","occupied runway was available")
	check(t:Release("27","AC1"),"runway release failed")
	allowed,reason=t:CanIssue("27","AC2","LANDING")
	check(allowed and reason=="available","released runway unavailable")
	check(t:SetHoldShort("27","AC2","FS2002"),"hold-short state failed")
	allowed,reason=t:CanIssue("27","AC1","TAKEOFF")
	check(not allowed and reason=="runway_hold_short","hold-short conflict was allowed")
	check(t:Release("27","AC2"),"hold-short release failed")
	check(not t:RegisterRunway(""),"invalid runway accepted")
	return true
end
return TrafficTest
