-- FlightSim ATC decision contract tests v0.1
local ATCDecision=require(script.Parent.ATCDecision)
local Test={}
local function check(c,m) if not c then error(m,2) end end
function Test.Run()
 local separation={GetConflicts=function() return {{AircraftA="A",AircraftB="B",DistanceM=80,VerticalSeparationFt=0,GroundConflict=true},{AircraftA="C",AircraftB="D",DistanceM=1000,VerticalSeparationFt=100,GroundConflict=false}} end}
 local d=ATCDecision.new(separation); local out=d:Step(); check(out.A and out.A.Instruction=="HOLD_POSITION","ground decision failed"); check(d:ShouldHold("B"),"ground hold lookup failed"); check(out.C and out.C.Instruction=="TRAFFIC_ALERT","air traffic alert failed"); check(not d:ShouldHold("C"),"airborne conflict incorrectly forced ground hold"); check(d:Get("UNKNOWN")==nil,"unknown aircraft decision should be nil"); return true
end
return Test
