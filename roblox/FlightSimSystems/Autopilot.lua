-- FlightSim autopilot / flight-director foundation v0.2
local Autopilot = {}
Autopilot.__index = Autopilot
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function err(t,c) return (t-c+540)%360-180 end
function Autopilot.new(state) return setmetatable({state=state},Autopilot) end
function Autopilot:Step(dt)
	local x=self.state:Get(); local ap=x.Autopilot
	if not ap.Enabled then x.Autopilot.CommandBank=0; x.Autopilot.CommandPitch=0; return end
	local nav=x.Navigation or {}; local v=x.VNAV or {}
	local targetH=nav.CommandHeading or ap.TargetHeading or x.Heading
	local targetA=(v.Mode=="VNAV" and v.TargetAltitude) or nav.CommandAltitude or ap.TargetAltitude or x.Altitude
	local he=err(targetH,x.Heading); local ae=targetA-x.Altitude
	local bank=clamp(he/30,-1,1)
	local pitch=clamp((ae/1200),-0.6,0.6)
	ap.CommandBank=bank; ap.CommandPitch=pitch; ap.Mode=(v.Mode=="VNAV" and "VNAV" or (nav.Mode=="LNAV" and "LNAV" or "HDG"))
	-- AP commands are kept separate from raw pilot inputs. FlightControls is
	-- responsible for blending them into the final actuator command.
	ap.CommandAileron=bank; ap.CommandElevator=pitch
end
return Autopilot
