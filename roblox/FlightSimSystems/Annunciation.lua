-- FlightSim cockpit annunciation / warning logic v0.1
-- Presentation-neutral: derives warnings from authoritative aircraft state.
local Annunciation={}; Annunciation.__index=Annunciation
local function ensure(x)
 x.Annunciation=x.Annunciation or {MasterWarning=false,MasterCaution=false,Fire=false,Stall=false,LowFuel=false,GearUnsafe=false,FlapOverspeed=false,HydraulicLow=false,ElectricalLoss=false,EngineOut=false,Messages={}}
 return x.Annunciation
end
function Annunciation.new(state) return setmetatable({state=state},Annunciation) end
function Annunciation:Step(dt)
 local x=self.state:Get(); local a=ensure(x); local msgs={}
 local fp=x.FireProtection or {}; local hyd=x.Hydraulic or {}; local elec=x.Electrical or {}; local gear=x.GearStatus or {}; local fuel=x.Fuel or {}; local engines=x.Engines or {}
 local fire=(fp.MasterFireWarning==true) or ((fp.Engines and ((fp.Engines[1] and fp.Engines[1].Fire) or (fp.Engines[2] and fp.Engines[2].Fire)))==true)
 local stall=x.StallWarning==true
 local gearUnsafe=(x.Airspeed or 0)>120 and gear.DownLocked~=true and (x.Altitude or 0)<3000
 local flapOver=(x.FlapSystem and x.FlapSystem.OverSpeed)==true
 local hydraulicLow=math.max(tonumber(hyd.A) or 0,tonumber(hyd.B) or 0)<900 and ((x.GroundContact~=true) or (x.Airspeed or 0)>30)
 local electricalLoss=not (elec.Bus1==true or elec.Bus2==true)
 local lowFuel=(tonumber(fuel.Total) or 0)<3000
 local engineOut=(engines[1] and engines[1].Running==false and (x.Airspeed or 0)>80) or (engines[2] and engines[2].Running==false and (x.Airspeed or 0)>80)
 if fire then table.insert(msgs,"FIRE") end; if stall then table.insert(msgs,"STALL") end; if gearUnsafe then table.insert(msgs,"GEAR UNSAFE") end; if flapOver then table.insert(msgs,"FLAP OVERSPEED") end; if hydraulicLow then table.insert(msgs,"HYDRAULIC LOW") end; if electricalLoss then table.insert(msgs,"ELECTRICAL") end; if lowFuel then table.insert(msgs,"LOW FUEL") end; if engineOut then table.insert(msgs,"ENGINE OUT") end
 a.Fire=fire; a.Stall=stall; a.GearUnsafe=gearUnsafe; a.FlapOverspeed=flapOver; a.HydraulicLow=hydraulicLow; a.ElectricalLoss=electricalLoss; a.LowFuel=lowFuel; a.EngineOut=engineOut
 a.MasterWarning=fire or stall or gearUnsafe or engineOut
 a.MasterCaution=(fp.MasterWarning==true and not fire) or flapOver or hydraulicLow or electricalLoss or lowFuel
 a.Messages=msgs
 x.Annunciation=a
end
return Annunciation
