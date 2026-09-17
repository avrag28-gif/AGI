-- FlightSim FMC active-leg regression tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local FMC=require(script.Parent.FMC)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Navigation={ActiveWaypoint=2,RouteComplete=false,DistanceToWaypoint=12000,BearingToWaypoint=135,CrossTrackError=-45},
  FMC={Route={
   {Ident="ORIG",Position=Vector3.new(0,0,0)},
   {Ident="FIX2",Position=Vector3.new(1000,0,0)},
   {Ident="FIX3",Position=Vector3.new(2000,0,0)}
  }}
 })
 local f=FMC.new(s)
 f:Step(1/60)
 local a=s.data.FMC.ActiveLeg
 check(s.data.FMC.ActiveWaypoint==2,"FMC must mirror the navigation active waypoint")
 check(s.data.FMC.LegIndex==2,"FMC leg index must follow the active waypoint")
 check(s.data.FMC.PreviousWaypoint=="ORIG","FMC must expose the previous waypoint ident")
 check(s.data.FMC.ActiveWaypointIdent=="FIX2","FMC must expose the active waypoint ident")
 check(s.data.FMC.NextWaypoint=="FIX3","FMC must expose the next waypoint ident")
 check(a.Distance==12000 and a.Bearing==135,"FMC active leg must mirror navigation distance and bearing")
 check(a.CrossTrackError==-45,"FMC active leg must mirror cross-track error")
 s.data.Navigation.RouteComplete=true
 f:Step(1/60)
 check(s.data.FMC.Active==false,"FMC must become inactive after route completion")
 check(s.data.FMC.ActiveLeg.RouteComplete==true,"FMC active-leg state must expose route completion")
 return true
end
return {Run=run}
