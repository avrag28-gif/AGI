-- FlightSim radio system v0.1
local Radio={}; Radio.__index=Radio
local RANGES={COM1={118,136.975},COM2={118,136.975},NAV1={108,117.95},NAV2={108,117.95},ADF1={190,1799},ADF2={190,1799}}
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
function Radio.new(state) return setmetatable({state=state},Radio) end
function Radio:Step(dt)
	local x=self.state:Get(); x.Radios=x.Radios or {}
	for name,range in pairs(RANGES) do
		local f=tonumber(x.Radios[name]); if finite(f) then x.Radios[name]=math.clamp(f,range[1],range[2]) else x.Radios[name]=range[1] end
	end
end
function Radio:Set(name,freq)
	name=string.upper(tostring(name)); local r=RANGES[name]; local f=tonumber(freq)
	if not r or not finite(f) or f<r[1] or f>r[2] then return false,"invalid_radio_frequency" end
	self.state:Get().Radios[name]=f; return true
end
return Radio
