-- FlightSim runway clearance coordinator v0.1
-- Coordinates runway reservations for the local simulation; not real-world ATC separation.
local ATCRunway={}; ATCRunway.__index=ATCRunway
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
local function ensure(x)
 x.ATC=x.ATC or {}
 x.ATC.Runway=x.ATC.Runway or {Clearance=nil,ReservationState="VACANT",Runway=nil,Sequence=0,LastResult=""}
 return x.ATC.Runway
end
function ATCRunway.new(state,traffic,aircraftId,callsign) return setmetatable({state=state,traffic=traffic,aircraftId=norm(aircraftId),callsign=norm(callsign)},ATCRunway) end
function ATCRunway:SetIdentity(aircraftId,callsign) self.aircraftId=norm(aircraftId); self.callsign=norm(callsign); return self.aircraftId~="" and self.callsign~="" end
function ATCRunway:RequestTakeoff(runwayId)
 local x=self.state:Get(); local r=ensure(x); local runway=norm(runwayId); if runway=="" then return false,"invalid_runway" end
 local ok,reason=self.traffic:CanIssue(runway,self.aircraftId,"TAKEOFF"); if not ok then r.LastResult=reason; return false,reason end
 local reserved,detail=self.traffic:Reserve(runway,self.aircraftId,self.callsign,"TAKEOFF"); if not reserved then r.LastResult=detail; return false,detail end
 r.Runway=runway; r.ReservationState="RESERVED"; r.Clearance="CLEARED FOR TAKEOFF "..runway; r.Sequence+=1; r.LastResult="TAKEOFF_RESERVED"; return true,r.Clearance
end
function ATCRunway:RequestLanding(runwayId)
 local x=self.state:Get(); local r=ensure(x); local runway=norm(runwayId); if runway=="" then return false,"invalid_runway" end
 local ok,reason=self.traffic:CanIssue(runway,self.aircraftId,"LANDING"); if not ok then r.LastResult=reason; return false,reason end
 local reserved,detail=self.traffic:Reserve(runway,self.aircraftId,self.callsign,"LANDING"); if not reserved then r.LastResult=detail; return false,detail end
 r.Runway=runway; r.ReservationState="RESERVED"; r.Clearance="CLEARED TO LAND "..runway; r.Sequence+=1; r.LastResult="LANDING_RESERVED"; return true,r.Clearance
end
function ATCRunway:EnterRunway()
 local x=self.state:Get(); local r=ensure(x); if not r.Runway then return false,"no_runway_reservation" end
 local ok,detail=self.traffic:SetOccupied(r.Runway,self.aircraftId); if not ok then r.LastResult=detail; return false,detail end
 r.ReservationState="OCCUPIED"; r.LastResult="RUNWAY_OCCUPIED"; return true
end
function ATCRunway:Release()
 local x=self.state:Get(); local r=ensure(x); if not r.Runway then return false,"no_runway_reservation" end
 local ok,detail=self.traffic:Release(r.Runway,self.aircraftId); if not ok then r.LastResult=detail; return false,detail end
 r.ReservationState="VACANT"; r.Clearance=nil; r.Runway=nil; r.LastResult="RUNWAY_RELEASED"; r.Sequence+=1; return true
end
function ATCRunway:Step(dt)
 local x=self.state:Get(); local r=ensure(x); r.ReservationState=r.ReservationState or "VACANT"
end
return ATCRunway
