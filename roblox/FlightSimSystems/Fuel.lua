-- FlightSim fuel system v0.3
-- Server-authoritative tank pumps, engine-specific feed paths, crossfeed and fuel telemetry.
local Fuel={}; Fuel.__index=Fuel
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.Fuel=x.Fuel or {Left=0,Center=0,Right=0,Total=0}
 x.FuelSystem=x.FuelSystem or {}
 local s=x.FuelSystem
 s.LeftQuantity=tonumber(s.LeftQuantity) or x.Fuel.Left or 0; s.CenterQuantity=tonumber(s.CenterQuantity) or x.Fuel.Center or 0; s.RightQuantity=tonumber(s.RightQuantity) or x.Fuel.Right or 0; s.TotalQuantity=tonumber(s.TotalQuantity) or x.Fuel.Total or 0
 s.LeftPump=s.LeftPump~=false; s.CenterPump=s.CenterPump~=false; s.RightPump=s.RightPump~=false; s.Crossfeed=s.Crossfeed==true
 s.EngineFeed=s.EngineFeed or {[1]="AUTO",[2]="AUTO"}; s.EngineFeed[1]=s.EngineFeed[1] or "AUTO"; s.EngineFeed[2]=s.EngineFeed[2] or "AUTO"
 s.LowFuel=s.LowFuel==true; s.Imbalance=tonumber(s.Imbalance) or 0; s.FeedPressure=tonumber(s.FeedPressure) or 0
 return x.Fuel,s
end
local function consume(tanks,name,demand)
 local take=math.min(math.max(0,tanks[name]),demand); tanks[name]-=take; return take,demand-take end
function Fuel.new(state) return setmetatable({state=state},Fuel) end
function Fuel:_engineDemand(x,index,flow,dt)
 if not (x.Engines[index] and x.Engines[index].Running and x.Engines[index].FuelOn) then return 0 end
 return math.max(0,tonumber(flow) or 0)*dt/60
end
function Fuel:_feedEngine(tanks,s,index,demand)
 if demand<=0 then return 0,"NONE" end
 local source=s.EngineFeed[index]
 local own=(index==1) and "Left" or "Right"
 local ownPump=(index==1) and s.LeftPump or s.RightPump
 local centerPump=s.CenterPump
 local taken=0
 if source=="LEFT" or (source=="AUTO" and own=="Left") then
  if own=="Left" and ownPump then taken=demand-consume(tanks,"Left",demand)
  elseif source=="LEFT" and s.LeftPump then taken=demand-consume(tanks,"Left",demand) end
 elseif source=="RIGHT" then
  if s.RightPump then taken=demand-consume(tanks,"Right",demand) end
 elseif source=="CENTER" then
  if centerPump then taken=demand-consume(tanks,"Center",demand) end
 else
  if centerPump and tanks.Center>0 then taken=demand-consume(tanks,"Center",demand) end
  if taken<demand and ownPump then local t=consume(tanks,own,demand-taken); taken+=t end
 end
 if taken<demand and s.Crossfeed then
  local other=(own=="Left") and "Right" or "Left"; local pump=(other=="Left") and s.LeftPump or s.RightPump
  if pump then local t=consume(tanks,other,demand-taken); taken+=t end
 end
 if taken<=0 then return 0,"NONE" end
 if source=="CENTER" or (source=="AUTO" and taken>0 and tanks.Center>=0) then return taken,(source=="AUTO" and "AUTO" or "CENTER") end
 return taken,(source=="AUTO" and own or source)
end
function Fuel:Step(dt)
 local x=self.state:Get(); local tanks,s=ensure(x)
 tanks.Left=math.max(0,tonumber(tanks.Left) or 0); tanks.Center=math.max(0,tonumber(tanks.Center) or 0); tanks.Right=math.max(0,tonumber(tanks.Right) or 0)
 local d1=self:_engineDemand(x,1,x.Engines[1] and x.Engines[1].FuelFlow,dt); local d2=self:_engineDemand(x,2,x.Engines[2] and x.Engines[2].FuelFlow,dt)
 local used1,src1=self:_feedEngine(tanks,s,1,d1); local used2,src2=self:_feedEngine(tanks,s,2,d2)
 if d1>0 and used1<d1 and x.Engines[1] then x.Engines[1].FuelOn=false end
 if d2>0 and used2<d2 and x.Engines[2] then x.Engines[2].FuelOn=false end
 tanks.Total=math.max(0,tanks.Left+tanks.Center+tanks.Right)
 s.LeftQuantity=tanks.Left; s.CenterQuantity=tanks.Center; s.RightQuantity=tanks.Right; s.TotalQuantity=tanks.Total
 s.LeftFeed=s.LeftPump and tanks.Left>0; s.RightFeed=s.RightPump and tanks.Right>0; s.CenterFeed=s.CenterPump and tanks.Center>0
 s.EngineFuelSource={[1]=src1,[2]=src2}; s.EngineFuelDemand={[1]=d1,[2]=d2}; s.EngineFuelDelivered={[1]=used1,[2]=used2}
 s.FeedPressure=clamp((s.LeftFeed or s.RightFeed or s.CenterFeed) and tanks.Total/30000 or 0,0,1)
 local wingMean=(tanks.Left+tanks.Right)/2
 s.Imbalance=wingMean>0 and (tanks.Left-tanks.Right)/wingMean or 0
 s.LowFuel=tanks.Total<3000
 x.Fuel=tanks
end
return Fuel
