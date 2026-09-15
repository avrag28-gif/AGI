-- FlightSim pitch trim system v0.1
local Trim={}; Trim.__index=Trim
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Trim.new(state) return setmetatable({state=state},Trim) end
function Trim:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}
 local target=clamp(tonumber(c.Trim) or 0,-1,1)
 x.TrimPitch=clamp((x.TrimPitch or 0)+target*2.5*dt,-10,10)
 -- Trim input represents pilot trim command; return it toward neutral after use.
 c.Trim=(tonumber(c.Trim) or 0)*math.max(0,1-5*dt)
end
return Trim
