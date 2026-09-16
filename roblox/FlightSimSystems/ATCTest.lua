-- FlightSim ATC contract tests v0.1
local ATC=require(script.Parent.ATC)
local function state()
 return {FMC={Destination="WIII",CruiseAltitude=33000},Navigation={ApproachRunway="24"},Transponder={Code="2000",Mode="STBY"}}
end
local function wrap(s) return {Get=function() return s end} end
local function run()
 local s=state(); local a=ATC.new(wrap(s)); assert(a:SetCallsign("LION123")); assert(a:SetPhase("COLD")); local ok,msg=a:RequestClearance("DEPARTURE"); assert(ok and type(msg)=="string"); assert(s.ATC.PendingReadback~=nil); local p=s.ATC.PendingReadback; local rb=a:Readback({Destination=p.Destination,Altitude=p.Altitude,Squawk=p.Squawk}); assert(rb==true); assert(s.ATC.ClearanceValid==true); assert(s.Transponder.Code==s.ATC.Squawk); local bad=ATC.new(wrap(state())); bad:SetPhase("COLD"); bad:RequestClearance("DEPARTURE"); local bp=bad.state:Get().ATC.PendingReadback; assert(bad:Readback({Destination=bp.Destination,Altitude=bp.Altitude,Squawk="7777")==false); return true end
return {Run=run}
