-- FlightSim separation contract tests v0.1
local ATCSeparation=require(script.Parent.ATCSeparation)
local Test={}
local function check(c,m) if not c then error(m,2) end end
local function registry(states)
 return {ForEach=function(_,cb) for _,v in ipairs(states) do cb(v.id,{Get=function() return v.state end},v.owner) end end}
end
function Test.Run()
 local states={
  {id="A",state={Position=Vector3.new(0,0,0),Altitude=5000,GroundContact=true},owner=nil},
  {id="B",state={Position=Vector3.new(100,0,0),Altitude=5000,GroundContact=true},owner=nil},
  {id="C",state={Position=Vector3.new(10000,0,0),Altitude=5000,GroundContact=false},owner=nil},
 }
 local s=ATCSeparation.new(registry(states)); local conflicts=s:Step(); check(#conflicts==1,"ground conflict detection failed"); local yes,c=s:IsConflicted("A"); check(yes and c.AircraftB=="B","aircraft conflict lookup failed")
 states[2].state.Position=Vector3.new(1000,0,0); conflicts=s:Step(); check(#conflicts==0,"ground threshold not respected")
 states[1].state.GroundContact=false; states[1].state.Position=Vector3.new(0,0,0); states[2].state.Position=Vector3.new(2000,0,0); states[1].state.Altitude=5000; states[2].state.Altitude=5100; conflicts=s:Step(); check(#conflicts==1,"air conflict detection failed")
 local ok,err=s:SetThresholds(200,3000,400); check(ok and err==nil,"threshold configuration failed")
 return true
end
return Test
