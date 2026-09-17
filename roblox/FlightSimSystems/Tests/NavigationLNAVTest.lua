-- Regression tests for Navigation LNAV guidance v1.2.
local Navigation=require(script.Parent.Parent.Navigation)
local function assertTrue(v,msg) assert(v,msg) end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function makeState(data) local state={data=data}; function state:Get() return self.data end; return state end

local route={
 {Ident="WP1",Position=Vector3.new(0,0,0),CaptureRadius=2500},
 {Ident="WP2",Position=Vector3.new(10000,0,0),CaptureRadius=2500},
}

local data={Position=Vector3.new(5000,0,1000),Velocity=Vector3.new(100,0,0),Heading=90,Autopilot={TargetHeading=90},Navigation={Mode="LNAV",ActiveWaypoint=2,Route=route,RouteComplete=false}}
local nav=Navigation.new(makeState(data)); nav:Step(1/60)
assertTrue(finite(data.Navigation.CommandHeading),"LNAV command must be finite")
assertTrue(finite(data.Navigation.CrossTrackError),"XTE must be finite")
assertTrue(finite(data.Navigation.LNAVInterceptAngle),"intercept angle must be finite")
assertTrue(finite(data.Navigation.LNAVTrackError),"track error must be finite")
assertTrue(math.abs(data.Navigation.CommandHeading-data.Navigation.PathCourse)<40,"LNAV correction must stay bounded")

-- No velocity: guidance must safely fall back to heading without runtime errors.
data={Position=Vector3.new(5000,0,1000),Velocity=Vector3.zero,Heading=90,Autopilot={TargetHeading=90},Navigation={Mode="LNAV",ActiveWaypoint=2,Route=route,RouteComplete=false}}
nav=Navigation.new(makeState(data)); nav:Step(1/60)
assertTrue(finite(data.Navigation.CommandHeading),"LNAV fallback command must be finite")

print("NavigationLNAVTest PASS")
return true
