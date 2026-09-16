-- FlightSim pitch trim system v0.2
-- Pilot trim command is integrated into the authoritative trim state.
local Trim={}; Trim.__index=Trim
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Trim.new(state) return setmetatable({state=state},Trim) end
function Trim:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local ap=x.Autopilot or {}
 local command=clamp(tonumber(c.Trim) or 0,-1,1)
 local rate=2.5
 x.TrimPitch=clamp((tonumber(x.TrimPitch) or 0)+command*rate*math.max(0,dt),-10,10)
 c.Trim=command*math.max(0,1-5*math.max(0,dt))
 x.TrimState=x.TrimState or {}
 x.TrimState.Command=command
 x.TrimState.Pitch=x.TrimPitch
 x.TrimState.Rate=rate
 x.TrimState.AutopilotTrimHold=ap.Enabled==true
 return true
end
return Trim
