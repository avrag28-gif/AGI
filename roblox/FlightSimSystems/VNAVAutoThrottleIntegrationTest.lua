-- FlightSim VNAV -> AutoThrottle integration tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local VNAV=require(script.Parent.VNAV)
local AutoThrottle=require(script.Parent.AutoThrottle)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({
  Altitude=30000,Airspeed=220,IndicatedAirspeed=220,Heading=0,
  Autopilot={Enabled=true,Mode="VNAV",TargetAltitude=30000,TargetHeading=0,TargetVerticalSpeed=0,TargetSpeed=220},
  Navigation={Mode="LNAV",ActiveWaypoint=1,DistanceToWaypoint=100000,Route={{Ident="DES",Position=Vector3.new(0,0,100000),Altitude=12000,AltitudeConstraint="AT",Speed=180,SpeedConstraint="AT"}},CommandAltitude=nil,CommandVerticalSpeed=nil},
  FMC={CruiseAltitude=30000},VNAV={Mode="VNAV"},
  Engines={[1]={Running=true,N1=90,Thrust=40000},[2]={Running=true,N1=90,Thrust=40000}},
  Throttle={[1]=0,[2]=0},AutoThrottle={Enabled=false,Active=false,ThrottleCommand={[1]=0,[2]=0}}
 })
 local v=VNAV.new(s); local at=AutoThrottle.new(s)
 v:Step(1/60)
 check(s.data.VNAV.TargetSpeed==180,"VNAV must publish the active waypoint speed")
 check(s.data.VNAV.SpeedConstraintType=="AT","VNAV must publish the active speed constraint type")
 at:SetEnabled(true)
 at:Step(1/60)
 check(s.data.AutoThrottle.Active==true,"autothrottle must activate when enabled with AP")
 check(s.data.AutoThrottle.TargetSpeed==180,"autothrottle must consume VNAV target speed")
 check(s.data.AutoThrottle.SpeedConstraintType=="AT","autothrottle must consume VNAV constraint type")
 check(s.data.Throttle[1]>0 and s.data.Throttle[2]>0,"autothrottle must command available engines")
 s.data.Navigation.ActiveWaypoint=2
 s.data.Navigation.Route[2]={Ident="SLOW",Position=Vector3.new(0,0,120000),Altitude=12000,AltitudeConstraint="AT",Speed=160,SpeedConstraint="BELOW"}
 v:Step(1/60); at:Step(1/60)
 check(s.data.VNAV.TargetSpeed==160,"VNAV must switch speed target with waypoint")
 check(s.data.VNAV.SpeedConstraintType=="BELOW","VNAV must switch speed constraint type with waypoint")
 check(s.data.AutoThrottle.TargetSpeed==160,"autothrottle must switch to the new VNAV speed")
 check(s.data.AutoThrottle.SpeedConstraintType=="BELOW","autothrottle must switch to the new VNAV constraint")
 s.data.IndicatedAirspeed=180; s.data.Airspeed=180
 at:Step(1/60)
 check(s.data.AutoThrottle.Protection=="NONE","below-speed constraint should not trigger overspeed protection")
 check(s.data.AutoThrottle.ThrottleCommand[1]<1 and s.data.AutoThrottle.ThrottleCommand[2]<1,"below-speed control should reduce throttle when above target")
 return true
end
return {Run=run}
