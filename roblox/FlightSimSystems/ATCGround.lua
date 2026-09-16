-- FlightSim ground ATC / taxi-clearance integration v0.1
-- Game simulation controller logic; no real-world ATC service or live clearance.
local ATCGround={}; ATCGround.__index=ATCGround
local function norm(v) return string.upper(tostring(v or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
local function ensure(x)
 x.ATC=x.ATC or {}; x.ATC.Ground=x.ATC.Ground or {Route=nil,RouteIndex=0,DestinationNode=nil,HoldShortNode=nil,TaxiActive=false,RunwayCrossingApproved=false,LastInstruction="",Sequence=0}; return x.ATC.Ground
end
function ATCGround.new(state,taxiRouter,atc) return setmetatable({state=state,router=taxiRouter,atc=atc},ATCGround) end
function ATCGround:RequestTaxi(destinationNode,holdShortNode)
 local x=self.state:Get(); local g=ensure(x); if not self.router then return false,"taxi_router_unavailable" end
 local start=x.GroundSteering and x.GroundSteering.TaxiNode or nil; if not start then return false,"aircraft_taxi_node_unknown" end
 local route,err=self.router:FindPath(start,destinationNode); if not route then return false,err end
 g.Route=route; g.RouteIndex=1; g.DestinationNode=norm(destinationNode); g.HoldShortNode=holdShortNode and norm(holdShortNode) or nil; g.TaxiActive=true; g.RunwayCrossingApproved=false; g.Sequence+=1; g.LastInstruction="TAXI TO "..g.DestinationNode..(g.HoldShortNode and " HOLD SHORT "..g.HoldShortNode or ""); return true,g.LastInstruction
end
function ATCGround:SetRunwayCrossingApproved(approved)
 local g=ensure(self.state:Get()); g.RunwayCrossingApproved=approved==true; return true end
function ATCGround:Step(dt)
 local x=self.state:Get(); local g=ensure(x); if not g.TaxiActive or not g.Route then return end
 local nodes=g.Route.Nodes; local idx=math.max(1,math.min(g.RouteIndex,#nodes)); local node=nodes[idx]; if not node then g.TaxiActive=false; return end
 local current=x.GroundSteering and x.GroundSteering.TaxiNode or nil
 if current and norm(current)==norm(node.Name) then
  if g.HoldShortNode and norm(node.Name)==g.HoldShortNode and not g.RunwayCrossingApproved then g.LastInstruction="HOLD SHORT "..g.HoldShortNode; return end
  if idx>=#nodes then g.TaxiActive=false; g.LastInstruction="TAXI COMPLETE" else g.RouteIndex=idx+1 end
 end
end
return ATCGround
