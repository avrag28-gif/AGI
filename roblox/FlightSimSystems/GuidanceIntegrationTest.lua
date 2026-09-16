-- FlightSim FMC/MCP/LNAV/VNAV guidance contract tests v0.1
-- Source-level tests; these are not Roblox runtime execution tests.
local FMC=require(script.Parent.FMC)
local MCP=require(script.Parent.MCP.v02)
local VNAV=require(script.Parent.VNAV)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function run()
 local s=state({Altitude=10000,Airspeed=220,IndicatedAirspeed=220,Position=Vector3.new(0,0,0),Autopilot={Enabled=false,Mode="OFF",TargetAltitude=10000,TargetSpeed=220,TargetHeading=0,TargetVerticalSpeed=0},Navigation={Route={},ActiveWaypoint=1,DistanceToWaypoint=10000},VNAV={},FMC={}})
 local fmc=FMC.new(s); local mcp=MCP.new(s); local vnav=VNAV.new(s)
 check(fmc:SetRoute("WIII","WARR",{{Ident="FIX1",Position=Vector3.new(0,0,10000),Altitude=nil,Speed=210,CaptureRadius=500}},35000),"valid route must be accepted")
 check(s.data.FMC.CruiseAltitude==35000,"FMC cruise altitude must be stored")
 check(mcp:SetAltitude(36000),"MCP altitude must accept valid value")
 check(mcp:SetMode("VNAV"),"MCP VNAV mode must activate")
 mcp:Step(1/60); vnav:Step(1/60)
 check(s.data.VNAV.Mode=="VNAV","VNAV must remain active in MCP VNAV mode")
 check(s.data.VNAV.TargetAltitude==35000,"VNAV must use FMC cruise altitude when active waypoint has no altitude constraint")
 check(s.data.Navigation.Mode=="LNAV","VNAV MCP mode must leave lateral navigation in LNAV")
 check(s.data.VNAV.TargetSpeed==210,"VNAV must consume waypoint speed constraint")
 check(mcp:SetMode("HDG"),"MCP HDG mode must activate")
 mcp:Step(1/60); vnav:Step(1/60); check(s.data.VNAV.Mode=="OFF" and s.data.Navigation.Mode=="HDG","switching away from VNAV must disable vertical VNAV")
 return true
end
return {Run=run}
