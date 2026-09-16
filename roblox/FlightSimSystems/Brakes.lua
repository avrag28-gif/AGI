-- FlightSim brake system v0.3
-- Pilot toe-brake input, parking brake, hydraulic availability and anti-skid foundation.
local Brakes={}; Brakes.__index=Brakes
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Brakes.new(state) return setmetatable({state=state},Brakes) end
function Brakes:Step(dt)
 local x=self.state:Get(); local b=x.Brakes
 local hydraulic=math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)
 local available=clamp(hydraulic/1800,0,1)
 local toe=clamp(tonumber(b.ToeBrake) or 0,0,1)
 local parking=b.Parking==true and 1 or 0
 local commanded=math.max(toe,parking)
 local target=commanded*available
 b.BrakePressure=(tonumber(b.BrakePressure) or 0)+(target-(tonumber(b.BrakePressure) or 0))*math.min(1,8*dt)
 b.BrakePressure=clamp(b.BrakePressure,0,1)
 local speed=math.max(x.Airspeed or 0,0)
 local antiSkid=b.AntiSkid~=false
 local slipProtection=1
 if antiSkid and speed<8 then slipProtection=clamp(speed/8,0,1) end
 b.LeftPressure=b.BrakePressure*slipProtection
 b.RightPressure=b.BrakePressure*slipProtection
 b.AntiSkid=antiSkid
end
return Brakes
