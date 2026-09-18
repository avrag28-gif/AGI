-- FlightSim MCP contract tests v0.1
-- Deterministic state-level checks; execute inside Roblox Studio/TestService.
local MCP=require(script.Parent.MCP)
local function expect(condition,message)
 assert(condition,message)
end
local function newState()
 local state={Autopilot={TargetHeading=0,TargetAltitude=0,TargetSpeed=nil,TargetVerticalSpeed=0,Mode="HDG",Enabled=false},MCP={Heading=0,Altitude=0,Speed=250,VerticalSpeed=0,HeadingMode="OFF",AltitudeMode="OFF",VerticalSpeedMode="OFF",FlightDirector=false},Navigation={Mode="HDG"},VNAV={Mode="OFF",CommandVerticalSpeed=0}}
 return {Get=function() return state end},state
end
local stateObj,x=newState(); local m=MCP.new(stateObj)
expect(m:SetHeading(725)==true,"heading should accept finite values")
expect(x.Autopilot.TargetHeading==5,"heading should wrap to 0..359")
expect(m:SetAltitude(65000)==true and x.Autopilot.TargetAltitude==60000,"altitude should clamp")
expect(m:SetSpeed(420)==true and x.Autopilot.TargetSpeed==350,"speed should clamp")
expect(m:SetVerticalSpeed(-9000)==true and x.Autopilot.TargetVerticalSpeed==-6000,"vertical speed should clamp")
expect(m:SetMode("VOR")==true and x.Autopilot.Mode=="VOR","VOR should be a valid MCP mode")
expect(m:SetMode("INVALID")==false,"invalid MCP mode must be rejected")
expect(m:SetHeading("nan")==false,"non-finite heading must be rejected")
expect(m:SetSpeed(math.huge)==false,"infinite speed must be rejected")
expect(m:SetVerticalSpeed(nil)==false,"missing vertical speed must be rejected")
m:SetMode("OFF")
expect(x.Autopilot.Enabled==false,"OFF mode must disable autopilot")
return true

expect(m:SetMode("HDG")==true and x.MCP.HeadingMode=="HDG SEL","HDG mode should update MCP annunciation")
m:Step(1/60)
expect(x.Navigation.CommandHeading==5,"HDG mode should feed commanded heading")
