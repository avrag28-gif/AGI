-- FlightSim airport procedure data contract tests v0.1
local Data=require(script.Parent.AirportProcedureData)
local function run()
 local good={ICAO="WIII",Name="TEST",Runways={{Ident="24",Heading=240,LengthM=3660,WidthM=45,ElevationFt=100,ILSFrequency=110.3}},SIDs={{Name="SID1",Runway="24",Waypoints={{Name="FIX1",Position=Vector3.new(0,0,0)}}}},STARs={{Name="STAR1",Runway="24",Waypoints={{Name="FIX2",Position=Vector3.new(100,0,100)}}}},TaxiNodes={{Name="A",Position=Vector3.zero},{Name="B",Position=Vector3.new(10,0,0)}},TaxiEdges={{From="A",To="B",DistanceM=10}}}
 local normalized,err=Data.Normalize(good); assert(normalized and not err); assert(Data.FindRunway(normalized,"24")~=nil); assert(Data.FindProcedure(normalized,"SID","SID1")~=nil); assert(Data.FindProcedure(normalized,"STAR","STAR1")~=nil)
 local bad={ICAO="WIII",Name="TEST",Runways={{Ident="24",Heading=240,LengthM=100}}}; assert(Data.ValidateAirport(bad)==false)
 return true
end
return {Run=run}
