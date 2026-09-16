-- FlightSim taxi routing contract tests v0.1
local TaxiRouting=require(script.Parent.TaxiRouting)
local function run()
 local a={TaxiNodes={{Name="A",Position=Vector3.zero},{Name="B",Position=Vector3.new(10,0,0)},{Name="C",Position=Vector3.new(20,0,0)},{Name="D",Position=Vector3.new(10,0,10)}},TaxiEdges={{From="A",To="B",DistanceM=10},{From="B",To="C",DistanceM=10},{From="A",To="D",DistanceM=30},{From="D",To="C",DistanceM=30}}}
 local r=TaxiRouting.new(a); assert(r:Build()); local route,err=r:FindPath("A","C"); assert(route and not err); assert(#route.Nodes==3); assert(math.abs(route.DistanceM-20)<1e-9); assert(r:ValidatePath(route)); local missing,bad=r:FindPath("A","X"); assert(missing==nil and bad=="unknown_taxi_node"); return true
end
return {Run=run}
