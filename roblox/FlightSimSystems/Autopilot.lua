-- FlightSim autopilot foundation v0.1
local Autopilot = {}
Autopilot.__index = Autopilot

local function clamp(v, lo, hi)
	return math.max(lo, math.min(hi, v))
end

local function wrapError(target, current)
	return (target - current + 540) % 360 - 180
end

function Autopilot.new(state)
	return setmetatable({state = state}, Autopilot)
end

function Autopilot:Step(dt)
	local x = self.state:Get()
	local ap = x.Autopilot
	if not ap.Enabled then
		return
	end

	local nav = x.Navigation
	local targetHeading = (nav and nav.CommandHeading) or ap.TargetHeading or x.Heading
	local targetAltitude = (nav and nav.CommandAltitude) or ap.TargetAltitude or x.Altitude

	local hdgError = wrapError(targetHeading, x.Heading)
	local altError = targetAltitude - x.Altitude

	-- Command surfaces through normalized flight-control inputs. This is a
	-- deliberately conservative foundation; aircraft-specific control laws
	-- will replace these gains as the 737 model is refined.
	x.Controls.Aileron = clamp(hdgError / 35, -1, 1)
	x.Controls.Elevator = clamp(altError / 1500, -0.65, 0.65)
end

return Autopilot
