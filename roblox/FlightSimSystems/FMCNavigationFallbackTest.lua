-- FlightSim FMC route-mirroring regression tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local FMC=require(script.Parent.FMC)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local route={
  {Ident="FIX1",Position=Vector3.new(1000,0,0)},
  {Ident="FIX2",Position=Vector3.new(2000,0,0)}
 }
 local s=state({
  Navigation={ActiveWaypoint=2,RouteComplete=false,Route=route,DistanceToWaypoint=5000,BearingToWaypoint=180,CrossTrackError=25},
  FMC={Route={}}
 })
 local f=FMC.new(s)
 f:Step(1/60)
 check(s.data.FMC.Route==route,"FMC must mirror a Navigation route when its own route is empty")
 check(s.data.FMC.ActiveWaypoint==2,"FMC must mirror Navigation active waypoint")
 check(s.data.FMC.ActiveWaypointIdent=="FIX2","FMC must expose the mirrored active waypoint")
 check(s.data.FMC.ActiveLeg.Distance==5000,"FMC active leg must use Navigation distance")
 check(s.data.FMC.ActiveLeg.Bearing==180,"FMC active leg must use Navigation bearing")
 check(s.data.FMC.ActiveLeg.CrossTrackError==25,"FMC active leg must use Navigation cross-track error")
 return true
end
return {Run=run}
