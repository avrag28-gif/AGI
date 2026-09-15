-- FlightSim flap detent / speed protection v0.1
local Flaps={}; Flaps.__index=Flaps
local DETENTS={0,1,2,5,10,15,25,30,40}
-- Game-simulation limits; tune against the selected aircraft data set later.
local VFE={0,250,250,230,210,195,180,165,145}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Flaps.new(state) return setmetatable({state=state},Flaps) end
function Flaps:Step(dt)
 local x=self.state:Get(); x.FlapSystem=x.FlapSystem or {Command=0,Detent=0,Target=0,VFE=250,OverSpeed=false}
 local requested=clamp(tonumber(x.Controls.Flap) or 0,0,1)
 local index=math.floor(requested*#DETENTS+0.5)+1
 index=clamp(index,1,#DETENTS)
 local detent=DETENTS[index]; local limit=VFE[index]
 local speed=x.Airspeed or 0
 local current=x.Surface.Flap or 0
 local currentIndex=clamp(math.floor(current*#DETENTS+0.5)+1,1,#DETENTS)
 local currentDetent=DETENTS[currentIndex]
 local target=detent
 if detent>currentDetent and speed>limit then target=currentDetent end
 x.Controls.Flap=target/40
 x.FlapSystem.Command=detent
 x.FlapSystem.Detent=currentDetent
 x.FlapSystem.Target=target
 x.FlapSystem.VFE=limit
 x.FlapSystem.OverSpeed=speed>limit and currentDetent>0
end
return Flaps
