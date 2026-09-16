-- FlightSim airport taxi routing graph v0.1
-- Deterministic shortest-path routing over validated airport taxi nodes/edges.
local TaxiRouting={}; TaxiRouting.__index=TaxiRouting
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function key(v) return string.upper(tostring(v or "")) end
local function edgeCost(e,nodes)
 local d=tonumber(e.DistanceM); if finite(d) and d>0 then return d end
 local a,b=nodes[key(e.From)],nodes[key(e.To)]; if a and b and typeof(a.Position)=="Vector3" and typeof(b.Position)=="Vector3" then return (a.Position-b.Position).Magnitude end
 return math.huge
end
function TaxiRouting.new(airport)
 return setmetatable({airport=airport or {},graph=nil},TaxiRouting)
end
function TaxiRouting:Build()
 local nodes={}; for _,n in ipairs(self.airport.TaxiNodes or {}) do local id=key(n.Name); if id~="" and typeof(n.Position)=="Vector3" then nodes[id]=n end end
 local graph={}; for id in pairs(nodes) do graph[id]={} end
 for _,e in ipairs(self.airport.TaxiEdges or {}) do local from,to=key(e.From),key(e.To); if graph[from] and graph[to] then local c=edgeCost(e,nodes); if c<math.huge then graph[from][#graph[from]+1]={To=to,Cost=c,Taxiway=e.Taxiway,HoldShort=e.HoldShort==true} end end end
 self.graph={Nodes=nodes,Edges=graph}; return true
end
function TaxiRouting:FindPath(from,to)
 if not self.graph then self:Build() end
 local s,t=key(from),key(to); if not self.graph.Nodes[s] or not self.graph.Nodes[t] then return nil,"unknown_taxi_node" end
 local dist,prev,used={}, {}, {}; for id in pairs(self.graph.Nodes) do dist[id]=math.huge end; dist[s]=0
 while true do local best=nil; local bestD=math.huge; for id,d in pairs(dist) do if not used[id] and d<bestD then best,bestD=id,d end end
  if not best then break end; used[best]=true; if best==t then break end
  for _,e in ipairs(self.graph.Edges[best] or {}) do local nd=bestD+e.Cost; if nd<dist[e.To] then dist[e.To]=nd; prev[e.To]={From=best,Edge=e} end end
 end
 if dist[t]==math.huge then return nil,"no_taxi_route" end
 local rev={}; local cur=t; while cur do rev[#rev+1]=cur; local p=prev[cur]; cur=p and p.From or nil end
 local path={}; for i=#rev,1,-1 do path[#path+1]=self.graph.Nodes[rev[i]] end
 return {Nodes=path,DistanceM=dist[t]}
end
function TaxiRouting:ValidatePath(route)
 if type(route)~="table" or type(route.Nodes)~="table" or #route.Nodes<1 then return false,"invalid_route" end
 return finite(route.DistanceM) and route.DistanceM>=0,"invalid_route_distance"
end
return TaxiRouting
