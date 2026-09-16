-- FlightSim navigation contract-test helpers v0.1
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local NavigationTest={}
local function range(v,a,b,msg)
 v=tonumber(v) or 0
 assert(v>=a and v<=b,msg)
end
function NavigationTest.Validate(state)
 local x=state:Get(); local n=x.Navigation or {}
 range(n.CommandHeading,0,360,"navigation heading out of range")
 range(n.HeadingError,-180,180,"navigation heading error out of range")
 assert((tonumber(n.DistanceToWaypoint) or 0)>=0,"waypoint distance must be non-negative")
 return true
end
function NavigationTest.ValidateRoute(state)
 local x=state:Get(); local n=x.Navigation or {}; local route=n.Route or {}
 assert((tonumber(n.ActiveWaypoint) or 1)>=1,"active waypoint must be >= 1")
 if #route>0 then assert((tonumber(n.ActiveWaypoint) or 1)<=#route,"active waypoint exceeds route") end
 return true
end
function NavigationTest.ValidateLNAV(state)
 local x=state:Get(); local n=x.Navigation or {}
 if n.Mode=="LNAV" then
  range(n.CrossTrackError,-100000,100000,"cross-track error invalid")
  range(n.CommandHeading,0,360,"LNAV command heading invalid")
 end
 return true
end
function NavigationTest.ValidateAll(state)
 NavigationTest.Validate(state)
 NavigationTest.ValidateRoute(state)
 NavigationTest.ValidateLNAV(state)
 return true
end
return NavigationTest
