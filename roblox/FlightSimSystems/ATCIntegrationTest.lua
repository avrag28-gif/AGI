-- FlightSim ATC runway/ground integration contract tests v0.1
local ATCTraffic=require(script.Parent.ATCTraffic)
local ATCSequencer=require(script.Parent.ATCSequencer)
local ATCRunway=require(script.Parent.ATCRunway)
local ATC=require(script.Parent.ATC)

local function check(c,m) if not c then error(m,2) end end
local function wrap(s) return {Get=function() return s end} end

local function newState(id)
 return {
  FMC={Destination="WIII",CruiseAltitude=33000},
  Navigation={ApproachRunway="24"},
  Transponder={Code="2000",Mode="STBY"},
  ATCDecision={Instruction="NONE"},
  GroundSteering={TaxiNode="A"},
  GroundContact=true,
  Position=Vector3.new(0,0,0),
  Altitude=0,
  Id=id,
 }
end

local function run()
 local traffic=ATCTraffic.new(); check(traffic:RegisterRunway("24"))
 local seq=ATCSequencer.new(traffic)
 local s1=newState("AC1"); local s2=newState("AC2")
 local r1=ATCRunway.new(wrap(s1),traffic,"AC1","FS1001",seq)
 local r2=ATCRunway.new(wrap(s2),traffic,"AC2","FS1002",seq)

 check(r1:RequestTakeoff("24"),"AC1 takeoff request was rejected")
 check(r2:RequestTakeoff("24"),"AC2 takeoff request was rejected")
 check(s1.ATC.Runway.Queued and s2.ATC.Runway.Queued,"runway requests were not queued")
 check(r2:EnterRunway()==false,"second aircraft bypassed sequence")
 check(r1:EnterRunway(),"first aircraft failed runway entry")
 check(traffic:GetRunway("24").State=="OCCUPIED","runway was not occupied")
 check(r2:EnterRunway()==false,"second aircraft entered occupied runway")
 check(r1:Release(),"first aircraft failed runway release")
 check(r2:EnterRunway(),"second aircraft failed after runway release")
 check(traffic:GetRunway("24").AircraftId=="AC2","runway ownership did not transfer")

 local hold=newState("AC3"); local r3=ATCRunway.new(wrap(hold),traffic,"AC3","FS1003",seq)
 hold.ATCDecision.Instruction="HOLD_POSITION"
 check(r3:RequestTakeoff("24")==false,"hold-position aircraft received runway request")
 check(r3:EnterRunway()==false,"hold-position aircraft entered runway")
 check(hold.ATC.Runway.LastResult=="HOLD_POSITION","hold-position decision was not propagated")

 local atcState=newState("AC4"); local atc=ATC.new(wrap(atcState)); check(atc:SetCallsign("FS1004")); check(atc:SetPhase("COLD"))
 local ok=atc:RequestClearance("DEPARTURE"); check(ok,"departure clearance failed")
 local pending=atcState.ATC.PendingReadback; check(pending~=nil,"departure readback was not pending")
 check(atc:Readback({Destination=pending.Destination,Altitude=pending.Altitude,Squawk=pending.Squawk}),"valid departure readback rejected")
 check(atcState.Transponder.Code==atcState.ATC.Squawk,"ATC squawk did not propagate")

 return true
end
return {Run=run}
