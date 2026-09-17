-- FlightSim pitch trim system v0.4
-- Pilot trim command is integrated into the authoritative trim state.
-- Autopilot trim is represented as a bounded simulation hold; it does not
-- silently overwrite pilot trim commands.
local Trim={}; Trim.__index=Trim
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Trim.new(state) return setmetatable({state=state},Trim) end
function Trim:Step(dt)
 local x=self.state:Get(); local c=x.Controls or {}; local ap=x.Autopilot or {}; dt=math.max(tonumber(dt) or 0,0)
 local command=clamp(tonumber(c.Trim) or 0,-1,1)
 local rate=2.5
 local trim=clamp(tonumber(x.TrimPitch) or 0,-10,10)
 -- Pilot trim input is always authoritative when present.
 trim=clamp(trim+command*rate*dt,-10,10)
 c.Trim=command*clamp(1-5*dt,0,1)
 x.TrimPitch=trim
 x.TrimState=x.TrimState or {}
 x.TrimState.Command=command
 x.TrimState.Pitch=trim
 x.TrimState.Rate=rate
 x.TrimState.AutopilotTrimHold=ap.Enabled==true
 x.TrimState.PilotCommandActive=math.abs(command)>0.001
 return true
end
return Trim
