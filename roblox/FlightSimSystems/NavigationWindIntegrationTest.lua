-- Navigation wind / ground-track integration regression tests v0.1
local State=require(script.Parent.State)
local Navigation=require(script.Parent.Navigation)
local function check(ok,msg) assert(ok,msg) end
local function makeState()
 local s=State.new()
 s.GroundContact=false
 s.Altitude=10000
 s.Airspeed=200
 s.Heading=0
 s.Position=Vector3.zero
 s.Velocity=Vector3.new(0,0,200*0.514444)
 s.Navigation.Mode="HDG"
 s.Navigation.Route={}
 return s
end
local function run()
 local calm=makeState()
 Navigation.new(calm):Step(1/60)
 local expected=200
 check(math.abs(calm.Navigation.GroundSpeed-expected)<0.01,"no-wind groundspeed must equal horizontal airspeed")
 check(math.abs(calm.Navigation.GroundTrack-0)<0.01,"heading 0 no-wind track must be 0 degrees")

 local headwind=makeState()
 headwind.WeatherEffects.WindVKts=-40
 headwind.Velocity=Vector3.new(0,0,(200-40)*0.514444)
 Navigation.new(headwind):Step(1/60)
 check(math.abs(headwind.Navigation.GroundSpeed-160)<0.01,"headwind must reduce groundspeed")
 check(math.abs(headwind.Navigation.GroundTrack-0)<0.01,"pure headwind must not change ground track")

 local crosswind=makeState()
 crosswind.WeatherEffects.WindUKts=40
 crosswind.Velocity=Vector3.new(40*0.514444,0,200*0.514444)
 Navigation.new(crosswind):Step(1/60)
 local expectedTrack=math.deg(math.atan2(40,200))
 local expectedGroundSpeed=math.sqrt(200*200+40*40)
 check(math.abs(crosswind.Navigation.GroundTrack-expectedTrack)<0.01,"crosswind must rotate ground track according to resultant ground velocity")
 check(math.abs(crosswind.Navigation.GroundSpeed-expectedGroundSpeed)<0.01,"crosswind groundspeed must use resultant horizontal velocity")

 local routeState=makeState()
 routeState.Navigation.Mode="LNAV"
 routeState.Navigation.Route={
  {Position=Vector3.new(0,0,10000),CaptureRadius=2500},
  {Position=Vector3.new(10000,0,10000),CaptureRadius=2500},
 }
 routeState.Navigation.ActiveWaypoint=2
 routeState.Position=Vector3.new(0,0,5000)
 routeState.Velocity=Vector3.new(0,0,200*0.514444)
 Navigation.new(routeState):Step(1/60)
 check(routeState.Navigation.PathCourse>80 and routeState.Navigation.PathCourse<100,"eastbound route must produce approximately 090 path course")
 check(routeState.Navigation.GroundSpeed>0,"navigation must expose positive groundspeed when moving")
 return true
end
return {Run=run}
