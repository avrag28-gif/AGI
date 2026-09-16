-- FlightSim fuel system v0.6
-- Server-authoritative tank pumps, engine-specific feed paths, crossfeed and fuel telemetry.
local Fuel={}; Fuel.__index=Fuel
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.Fuel=x.Fuel or {Left=0,Center=0,Right=0,Total=0}
 x.FuelSystem=x.FuelSystem or {}
 local s=x.FuelSystem; local ff=x.Failures and x.Failures.Fuel or {}
 s.LeftQuantity=tonumber(s.LeftQuantity) or x.Fuel.Left or 0; s.CenterQuantity=tonumber(s.CenterQuantity) or x.Fuel.Center or 0; s.RightQuantity=tonumber(s.RightQuantity) or x.Fuel.Right or 0; s.TotalQuantity=tonumber(s.TotalQuantity) or x.Fuel.Total or 0
 s.LeftPump=s.LeftPump~=false and ff.LeftPump~=true; s.CenterPump=s.CenterPump~=false and ff.CenterPump~=true; s.RightPump=s.RightPump~=false and ff.RightPump~=true; s.Crossfeed=s.Crossfeed==true and ff.Crossfeed~=true
 s.EngineFeed=s.EngineFeed or {[1]="AUTO",[2]="AUTO"}; s.EngineFeed[1]=s.EngineFeed[1] or "AUTO"; s.EngineFeed[2]=s.EngineFeed[2] or "AUTO"
 s.EngineFuelAvailable=s.EngineFuelAvailable or {[1]=true,[2]=true}
 s.LowFuel=s.LowFuel==true; s.Imbalance=tonumber(s.Imbalance) or 0; s.FeedPressure=tonumber(s.FeedPressure) or 0
 return x.Fuel,s
end
local function consume(tanks,name,demand)
 local take=math.min(math.max(0,tanks[name]),demand); tanks[name]-=take; return take
end
function Fuel.new(state) return setmetatable({state=state},Fuel) end
function Fuel:_engineDemand(x,index,flow,dt)
 if not (x.Engines[index] and x.Engines[index].Running and x.Engines[index].FuelOn) then return 0 end
 return math.max(0,tonumber(flow) or 0)*dt/60
end
function Fuel:_trySource(tanks,s,name,demand)
 if demand<=0 then return 0 end
 if name=="Left" and s.LeftPump then return consume(tanks,"Left",demand) end
 if name=="Right" and s.RightPump then return consume(tanks,"Right",demand) end
 if name=="Center" and s.CenterPump then return consume(tanks,"Center",demand) end
 return 0
end
function Fuel:_feedEngine(tanks,s,index,demand)
 if demand<=0 then return 0,"NONE" end
 local source=s.EngineFeed[index]
 local own=(index==1) and "Left" or "Right"; local other=(own=="Left") and "Right" or "Left"
 local used=0; local sources={}
 local function take(name,label)
  local amount=self:_trySource(tanks,s,name,demand-used)
  if amount>0 then used+=amount; table.insert(sources,label or name) end
 end
 if source=="LEFT" then take("Left","LEFT") elseif source=="RIGHT" then take("Right","RIGHT") elseif source=="CENTER" then take("Center","CENTER") else
  take("Center","CENTER"); if used<demand then take(own,own=="Left" and "LEFT" or "RIGHT") end
 end
 if used<demand and s.Crossfeed then take(other,other=="Left" and "LEFT_XFEED" or "RIGHT_XFEED") end
 return used,(#sources>0 and table.concat(sources,"+") or "NONE")
end
function Fuel:_pathAvailable(s,tanks,index)
 local source=s.EngineFeed[index]
 local own=(index==1) and "Left" or "Right"; local other=(own=="Left") and "Right" or "Left"
 local function usable(name)
  if name=="Left" then return s.LeftPump and tanks.Left>0 end
  if name=="Right" then return s.RightPump and tanks.Right>0 end
  if name=="Center" then return s.CenterPump and tanks.Center>0 end
  return false
 end
 if source=="LEFT" then return usable("Left") end
 if source=="RIGHT" then return usable("Right") end
 if source=="CENTER" then return usable("Center") end
 return usable("Center") or usable(own) or (s.Crossfeed and usable(other))
end
function Fuel:Step(dt)
 local x=self.state:Get(); local tanks,s=ensure(x)
 tanks.Left=math.max(0,tonumber(tanks.Left) or 0); tanks.Center=math.max(0,tonumber(tanks.Center) or 0); tanks.Right=math.max(0,tonumber(tanks.Right) or 0)
 s.EngineFuelAvailable[1]=self:_pathAvailable(s,tanks,1); s.EngineFuelAvailable[2]=self:_pathAvailable(s,tanks,2)
 local d1=self:_engineDemand(x,1,x.Engines[1] and x.Engines[1].FuelFlow,dt); local d2=self:_engineDemand(x,2,x.Engines[2] and x.Engines[2].FuelFlow,dt)
 local used1,src1=self:_feedEngine(tanks,s,1,d1); local used2,src2=self:_feedEngine(tanks,s,2,d2)
 if d1>0 and used1<=0 and x.Engines[1] then x.Engines[1].FuelOn=false end; if d2>0 and used2<=0 and x.Engines[2] then x.Engines[2].FuelOn=false end
 tanks.Total=math.max(0,tanks.Left+tanks.Center+tanks.Right)
 s.LeftQuantity=tanks.Left; s.CenterQuantity=tanks.Center; s.RightQuantity=tanks.Right; s.TotalQuantity=tanks.Total
 s.LeftFeed=s.LeftPump and tanks.Left>0; s.RightFeed=s.RightPump and tanks.Right>0; s.CenterFeed=s.CenterPump and tanks.Center>0
 s.EngineFuelSource={[1]=src1,[2]=src2}; s.EngineFuelDemand={[1]=d1,[2]=d2}; s.EngineFuelDelivered={[1]=used1,[2]=used2}; s.EngineFuelStarved={[1]=d1>0 and used1<=0,[2]=d2>0 and used2<=0}
 s.EngineFuelAvailable[1]=s.EngineFuelAvailable[1] or used1>0; s.EngineFuelAvailable[2]=s.EngineFuelAvailable[2] or used2>0
 s.FeedPressure=clamp((s.LeftFeed or s.RightFeed or s.CenterFeed) and tanks.Total/30000 or 0,0,1)
 local wingMean=(tanks.Left+tanks.Right)/2; s.Imbalance=wingMean>0 and (tanks.Left-tanks.Right)/wingMean or 0; s.LowFuel=tanks.Total<3000
 x.Fuel=tanks
end
return Fuel
