-- FlightSim ground ATC contract tests v0.1
local Ground=require(script.Parent.ATCGround)
local function run()
 local s={GroundSteering={TaxiNode="A"}}; local route={FindPath=function(_,a,b) assert(a=="A" and b=="C"); return {Nodes={{Name="A"},{Name="B"},{Name="C"}},DistanceM=20} end}; local atc=Ground.new({Get=function() return s end},route,{})
 local ok,msg=atc:RequestTaxi("C","B"); assert(ok and msg=="TAXI TO C HOLD SHORT B"); atc:Step(1/60); assert(s.ATC.Ground.RouteIndex==1); s.GroundSteering.TaxiNode="B"; atc:Step(1/60); assert(s.ATC.Ground.LastInstruction=="HOLD SHORT B"); atc:SetRunwayCrossingApproved(true); atc:Step(1/60); assert(s.ATC.Ground.RouteIndex==3); s.GroundSteering.TaxiNode="C"; atc:Step(1/60); assert(s.ATC.Ground.TaxiActive==false); assert(s.ATC.Ground.LastInstruction=="TAXI COMPLETE"); return true
end
return {Run=run}
