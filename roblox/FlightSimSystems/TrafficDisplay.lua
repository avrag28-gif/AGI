-- FlightSim traffic display / TCAS presentation model v0.2
-- Converts TCAS intruders into an ND-style relative traffic representation.
local TrafficDisplay={}; TrafficDisplay.__index=TrafficDisplay
local function wrap180(v) v=((v+180)%360)-180; return v end
local function finite(v,d) v=tonumber(v); if not v or v~=v or v==math.huge or v==-math.huge then return d end; return v end
function TrafficDisplay.new(state) return setmetatable({state=state},TrafficDisplay) end
function TrafficDisplay:Step()
 local x=self.state:Get(); local t=x.TCAS or {}; local a=t.Advisories or {}; local ownPos=x.Position; local ownHeading=finite(x.Heading,0); local ownAlt=finite(x.Altitude,0); local out={Powered=t.Powered==true,Level=t.HighestLevel or "NONE",ClosestIntruder=t.ClosestIntruder,ClosestRangeM=t.ClosestRangeM,Targets={}}
 if typeof(ownPos)~="Vector3" then x.TCASDisplay=out; return out end
 for _,v in ipairs(a) do
  local target=self.state.Registry and nil
  local range=finite(v.RangeM,nil); local vertical=finite(v.VerticalSeparationFt,nil)
  local bearing=nil; local relativeBearing=nil; local horizontal=nil
  if typeof(v.Position)=="Vector3" then
   horizontal=Vector3.new(v.Position.X-ownPos.X,0,v.Position.Z-ownPos.Z); range=horizontal.Magnitude; if range>0.001 then bearing=(math.deg(math.atan2(horizontal.X,horizontal.Z))+360)%360; relativeBearing=wrap180(bearing-ownHeading) end
  end
  out.Targets[#out.Targets+1]={Intruder=v.Intruder,RangeM=range,VerticalSeparationFt=vertical,Level=v.Level,Bearing=bearing,RelativeBearing=relativeBearing,RelativeAltitudeFt=(finite(v.Altitude,ownAlt)-ownAlt),Quadrant=relativeBearing and (relativeBearing>=-45 and relativeBearing<45 and "AHEAD" or relativeBearing>=45 and relativeBearing<135 and "RIGHT" or relativeBearing>=-135 and relativeBearing<-45 and "LEFT" or "BEHIND") or "UNKNOWN"}
 end
 table.sort(out.Targets,function(a1,b1) return (a1.RangeM or math.huge)<(b1.RangeM or math.huge) end); x.TCASDisplay=out; return out
end
return TrafficDisplay
