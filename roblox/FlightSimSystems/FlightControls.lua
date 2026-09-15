-- FlightSim flight-control system v0.2
-- Blends pilot commands with autopilot commands before hydraulic actuation.
local FlightControls={}; FlightControls.__index=FlightControls
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function FlightControls.new(state) return setmetatable({state=state},FlightControls) end
function FlightControls:Step(dt)
	local x=self.state:Get(); local c=x.Controls; local ap=x.Autopilot or {}
	local authority=clamp(math.max(x.Hydraulic.A or 0,x.Hydraulic.B or 0)/1800,0,1)
	x.Surface=x.Surface or {Aileron=0,Elevator=0,Rudder=0,Flap=0}
	local ail=clamp(c.Aileron or 0,-1,1); local ele=clamp(c.Elevator or 0,-1,1)
	if ap.Enabled then
		ail=clamp(ap.CommandAileron or ail,-1,1); ele=clamp(ap.CommandElevator or ele,-1,1)
	end
	x.Surface.Aileron += (ail*authority-x.Surface.Aileron)*math.min(1,8*dt)
	x.Surface.Elevator += (ele*authority-x.Surface.Elevator)*math.min(1,8*dt)
	x.Surface.Rudder += (clamp(c.Rudder or 0,-1,1)*authority-x.Surface.Rudder)*math.min(1,6*dt)
	x.Surface.Flap += (clamp(c.Flap or 0,0,1)-x.Surface.Flap)*math.min(1,2*dt)
end
return FlightControls
