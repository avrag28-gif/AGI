-- FlightSim brake system v0.5
-- Simulation approximation: toe brakes, parking brake, hydraulic availability and anti-skid.
-- Brake pressure is normalized 0..1; wheel pressure is exposed separately for physics/instruments.
local Brakes={}; Brakes.__index=Brakes
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Brakes.new(state) return setmetatable({state=state},Brakes) end
function Brakes:Step(dt)
 local x=self.state:Get(); local b=x.Brakes or {}; x.Brakes=b; local h=x.Hydraulic or {}; dt=math.max(tonumber(dt) or 0,0)
 local pressureA=math.max(tonumber(h.A) or 0,0); local pressureB=math.max(tonumber(h.B) or 0,0); local hydraulic=math.max(pressureA,pressureB); local available=clamp(hydraulic/1800,0,1)
 local toe=clamp(tonumber(b.ToeBrake) or 0,0,1); local parking=b.Parking==true and 1 or 0; local commanded=math.max(toe,parking); local target=commanded*available
 local current=clamp(tonumber(b.BrakePressure) or 0,0,1); b.BrakePressure=clamp(current+(target-current)*math.min(1,8*dt),0,1)
 local speed=math.max(tonumber(x.Airspeed) or 0,0); local antiSkid=b.AntiSkid~=false; local slipProtection=1
 if antiSkid and speed<8 then slipProtection=clamp(speed/8,0,1) end
 b.LeftPressure=b.BrakePressure*slipProtection; b.RightPressure=b.BrakePressure*slipProtection; b.AntiSkid=antiSkid; b.HydraulicAvailable=available>0.05; b.ParkingApplied=parking>0; b.BrakeDemand=commanded
 x.HydraulicDemand=x.HydraulicDemand or {}; x.HydraulicDemand.Brakes=clamp(b.BrakePressure,0,1)
end
return Brakes
