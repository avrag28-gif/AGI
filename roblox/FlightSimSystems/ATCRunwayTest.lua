-- FlightSim runway coordinator contract tests v0.1
local ATCTraffic=require(script.Parent.ATCTraffic)
local ATCRunway=require(script.Parent.ATCRunway)
local RunwayTest={}
local function check(c,m) if not c then error(m,2) end end
local function mockState()
 local x={}; return {Get=function() return x end}
end
function RunwayTest.Run()
 local traffic=ATCTraffic.new(); check(traffic:RegisterRunway("27"),"register failed")
 local s1=mockState(); local a1=ATCRunway.new(s1,traffic,"AC1","FS1001")
 local ok,msg=a1:RequestTakeoff("27"); check(ok and msg=="CLEARED FOR TAKEOFF 27","takeoff clearance failed")
 check(a1:EnterRunway(),"enter runway failed")
 local s2=mockState(); local a2=ATCRunway.new(s2,traffic,"AC2","FS1002")
 ok,msg=a2:RequestLanding("27"); check(not ok and msg=="runway_occupied","landing conflict allowed")
 check(a1:Release(),"release failed")
 ok,msg=a2:RequestLanding("27"); check(ok and msg=="CLEARED TO LAND 27","landing clearance failed")
 check(a2:EnterRunway(),"landing occupancy failed")
 check(a2:Release(),"landing release failed")
 return true
end
return RunwayTest
