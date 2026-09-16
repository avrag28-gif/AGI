-- FlightSim traffic display deterministic contract tests v0.1
local TrafficDisplay=require(script.Parent.TrafficDisplay)
local function stateOf(x) return {Get=function() return x end} end
local function assertEq(a,b,m) assert(a==b,(m or "assertEq")..": expected "..tostring(b)..", got "..tostring(a)) end
local function assertNear(a,b,e,m) assert(math.abs(a-b)<=e,(m or "assertNear")..": expected "..tostring(b)..", got "..tostring(a)) end
local function run()
 local own={Position=Vector3.zero,Heading=0,Altitude=10000,TCAS={Powered=true,HighestLevel="TA",Advisories={{Intruder="B",RangeM=1000,VerticalSeparationFt=300,Level="TA",Position=Vector3.new(0,0,-1000),Altitude=10300},{Intruder="A",RangeM=2000,VerticalSeparationFt=200,Level="TA",Position=Vector3.new(1000,0,0),Altitude=9800}}}}
 local d=TrafficDisplay.new(stateOf(own)); local out=d:Step(); assertEq(#out.Targets,2,"target count"); assertEq(out.Targets[1].Intruder,"B","nearest target"); assertNear(out.Targets[1].RelativeBearing,0,0.01,"ahead bearing"); assertEq(out.Targets[1].Quadrant,"AHEAD","ahead quadrant"); assertEq(out.Targets[1].RelativeAltitudeFt,300,"relative altitude"); assertNear(out.Targets[2].RelativeBearing,90,0.01,"right bearing"); assertEq(out.Targets[2].Quadrant,"RIGHT","right quadrant"); assertEq(own.TCASDisplay,out,"state output"); return true
end
return {Run=run}
