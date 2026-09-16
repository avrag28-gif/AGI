-- FlightSim guidance sign contract tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local Navigation=require(script.Parent.Navigation)
local Approach=require(script.Parent.Approach)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Position=Vector3.new(0,0,0),Heading=0,Altitude=3000,Airspeed=140,Autopilot={TargetHeading=0,TargetAltitude=3000},Navigation={Mode="APP",Route={},ActiveWaypoint=1}}
end
local function run()
 local s=state(base()); local approach=Approach.new(s); local nav=Navigation.new(s)
 check(approach:SetRunway({Position=Vector3.new(0,0,0),Heading=0,Elevation=0,GlideSlope=3,LocalizerLength=20000,ILSFrequency=110.3,ILSIdent="TEST"}))
 s.data.Radios={NAV1=110.3}; s.data.Avionics={Radios=true}
 -- Heading 0 points +Z. Negative X is left of runway centerline.
 s.data.Position=Vector3.new(-1000,0,-10000); approach:Step(1/60)
 check(s.data.Navigation.ILS.Localizer>0,"left-of-centerline geometry must produce positive localizer correction")
 nav:Step(1/60); check(s.data.Navigation.CommandHeading>0 and s.data.Navigation.CommandHeading<180,"APP guidance must turn toward runway centerline")
 s.data.Position=Vector3.new(1000,0,-10000); approach:Step(1/60); nav:Step(1/60)
 check(s.data.Navigation.ILS.Localizer<0,"right-of-centerline geometry must produce negative localizer correction")
 check(s.data.Navigation.CommandHeading>180 and s.data.Navigation.CommandHeading<360,"APP guidance must turn toward runway centerline from the right")
 return true
end
return {Run=run}
