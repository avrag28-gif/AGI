-- FlightSim traffic display / TCAS presentation model v0.1
local TrafficDisplay={}; TrafficDisplay.__index=TrafficDisplay
function TrafficDisplay.new(state) return setmetatable({state=state},TrafficDisplay) end
function TrafficDisplay:Step()
 local x=self.state:Get(); local t=x.TCAS or {}; local a=t.Advisories or {}; local out={Powered=t.Powered==true,Level=t.HighestLevel or "NONE",ClosestIntruder=t.ClosestIntruder,ClosestRangeM=t.ClosestRangeM,Targets={}}
 for i,v in ipairs(a) do out.Targets[i]={Intruder=v.Intruder,RangeM=v.RangeM,VerticalSeparationFt=v.VerticalSeparationFt,Level=v.Level} end
 x.TCASDisplay=out; return out
end
return TrafficDisplay
