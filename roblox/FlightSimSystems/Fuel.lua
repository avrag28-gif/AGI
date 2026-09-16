-- FlightSim fuel system v0.2
-- Server-authoritative tank accounting, engine feed, low-fuel and imbalance telemetry.
local Fuel={}; Fuel.__index=Fuel
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function ensure(x)
 x.Fuel=x.Fuel or {Left=0,Center=0,Right=0,Total=0}
 x.FuelSystem=x.FuelSystem or {LeftQuantity=0,CenterQuantity=0,RightQuantity=0,TotalQuantity=0,LeftFeed=true,RightFeed=true,CenterFeed=true,LowFuel=false,Imbalance=0,FeedPressure=0}
 return x.Fuel,x.FuelSystem
end
function Fuel.new(state) return setmetatable({state=state},Fuel) end
function Fuel:Step(dt)
 local x=self.state:Get(); local tanks,s=ensure(x)
 tanks.Left=math.max(0,tonumber(tanks.Left) or 0); tanks.Center=math.max(0,tonumber(tanks.Center) or 0); tanks.Right=math.max(0,tonumber(tanks.Right) or 0)
 local flow1=(x.Engines[1] and x.Engines[1].Running and x.Engines[1].FuelOn) and math.max(0,tonumber(x.Engines[1].FuelFlow) or 0) or 0
 local flow2=(x.Engines[2] and x.Engines[2].Running and x.Engines[2].FuelOn) and math.max(0,tonumber(x.Engines[2].FuelFlow) or 0) or 0
 local demand=(flow1+flow2)*dt/60
 local centerTake=math.min(tanks.Center,demand); tanks.Center-=centerTake; demand-=centerTake
 if demand>0 then
  local wing=tanks.Left+tanks.Right
  if wing>0 then
   local l=demand*(tanks.Left/wing); local r=demand-l
   tanks.Left=math.max(0,tanks.Left-l); tanks.Right=math.max(0,tanks.Right-r)
  end
 end
 tanks.Total=math.max(0,tanks.Left+tanks.Center+tanks.Right)
 s.LeftQuantity=tanks.Left; s.CenterQuantity=tanks.Center; s.RightQuantity=tanks.Right; s.TotalQuantity=tanks.Total
 s.LeftFeed=tanks.Left>0; s.RightFeed=tanks.Right>0; s.CenterFeed=tanks.Center>0
 s.FeedPressure=clamp(tanks.Total/30000,0,1)
 local wingMean=(tanks.Left+tanks.Right)/2
 s.Imbalance=wingMean>0 and (tanks.Left-tanks.Right)/wingMean or 0
 s.LowFuel=tanks.Total<3000
end
return Fuel
