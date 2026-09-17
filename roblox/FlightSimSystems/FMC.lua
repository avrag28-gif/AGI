-- FlightSim FMC/CDU data model v0.5
-- Validates route data and exposes active-leg/progress data for VNAV and navigation.
local FMC={}; FMC.__index=FMC
local MAX_WAYPOINTS=64; local MAX_IDENT=8
local function ident(v) local s=string.upper(string.sub(tostring(v or ""),1,MAX_IDENT)); return s:match("^[A-Z0-9%-%._]+$") and s or "" end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function copyWaypoint(w)
 if type(w)~="table" or typeof(w.Position)~="Vector3" then return nil end
 local alt=w.Altitude; if alt~=nil and (not finite(tonumber(alt)) or alt<0 or alt>60000) then return nil end
 local c=string.upper(tostring(w.AltitudeConstraint or "AT")); if c~="AT" and c~="ABOVE" and c~="BELOW" then return nil end
 local minAlt=w.MinAltitude; local maxAlt=w.MaxAltitude
 if minAlt~=nil and (not finite(tonumber(minAlt)) or minAlt<0 or minAlt>60000) then return nil end
 if maxAlt~=nil and (not finite(tonumber(maxAlt)) or maxAlt<0 or maxAlt>60000) then return nil end
 if minAlt and maxAlt and tonumber(minAlt)>tonumber(maxAlt) then return nil end
 local speed=w.Speed; if speed~=nil and (not finite(tonumber(speed)) or speed<0 or speed>500) then return nil end
 local sc=string.upper(tostring(w.SpeedConstraint or "AT")); if sc~="AT" and sc~="ABOVE" and sc~="BELOW" then return nil end
 return {Ident=ident(w.Ident),Position=w.Position,Altitude=alt and tonumber(alt) or nil,AltitudeConstraint=c,MinAltitude=minAlt and tonumber(minAlt) or nil,MaxAltitude=maxAlt and tonumber(maxAlt) or nil,Speed=speed and tonumber(speed) or nil,SpeedConstraint=sc,CaptureRadius=math.clamp(tonumber(w.CaptureRadius) or 2500,250,10000)}
end
function FMC.new(state) return setmetatable({state=state,page="IDENT",scratch=""},FMC) end
function FMC:Step(dt)
 local x=self.state:Get(); x.FMC=x.FMC or {}; local f=x.FMC; local nav=x.Navigation or {}; local route=f.Route or nav.Route or {}
 local index=math.clamp(math.floor(tonumber(nav.ActiveWaypoint) or 1),1,math.max(1,#route))
 f.Page=f.Page or self.page; f.Scratchpad=f.Scratchpad or self.scratch; f.ActiveWaypoint=index; f.LegIndex=index; f.RouteComplete=nav.RouteComplete==true; f.Active=(#route>0) and not f.RouteComplete
 local previous=route[index-1]; local active=route[index]; local next=route[index+1]
 f.PreviousWaypoint=previous and previous.Ident or nil
 f.ActiveWaypointIdent=active and active.Ident or nil
 f.NextWaypoint=next and next.Ident or nil
 f.ActiveLeg={
  Index=index,
  PreviousIdent=f.PreviousWaypoint,
  ActiveIdent=f.ActiveWaypointIdent,
  NextIdent=f.NextWaypoint,
  Distance=finite(nav.DistanceToWaypoint) and nav.DistanceToWaypoint or 0,
  Bearing=finite(nav.BearingToWaypoint) and nav.BearingToWaypoint or 0,
  CrossTrackError=finite(nav.CrossTrackError) and nav.CrossTrackError or 0,
  RouteComplete=f.RouteComplete,
 }
end
function FMC:SetPage(page) local p=string.upper(string.sub(tostring(page or "IDENT"),1,16)); local allowed={IDENT=true,RTE=true,LEGS=true,DEPARR=true,PERF=true,PROG=true,NAVRAD=true}; if not allowed[p] then return false,"invalid_page" end; local x=self.state:Get(); x.FMC=x.FMC or {}; x.FMC.Page=p; self.page=p; return true end
function FMC:SetScratchpad(text) local x=self.state:Get(); x.FMC=x.FMC or {}; x.FMC.Scratchpad=string.upper(string.sub(tostring(text or ""),1,80)); self.scratch=x.FMC.Scratchpad; return true end
function FMC:SetRoute(origin,destination,route,cruiseAltitude)
 if type(route)~="table" or #route>MAX_WAYPOINTS then return false,"invalid_route" end
 local o,d=ident(origin),ident(destination); if o=="" or d=="" then return false,"invalid_airport" end
 local ca=tonumber(cruiseAltitude); if ca and (not finite(ca) or ca<0 or ca>60000) then return false,"invalid_cruise_altitude" end
 local clean={}; for i=1,#route do local w=copyWaypoint(route[i]); if not w then return false,"invalid_waypoint_"..i end; clean[i]=w end
 local x=self.state:Get(); x.FMC=x.FMC or {}; x.FMC.Origin=o; x.FMC.Destination=d; x.FMC.Route=clean; x.FMC.CruiseAltitude=ca; x.FMC.Active=#clean>0; x.FMC.ActiveWaypoint=1; x.FMC.RouteComplete=#clean==0; x.Navigation.Route=clean; x.Navigation.ActiveWaypoint=1; x.Navigation.RouteComplete=#clean==0; return true
end
return FMC
