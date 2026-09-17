-- FlightSim authoritative state invariant monitor v1.2
-- Validates the current authoritative State contract after each simulation tick.
local StateIntegrity={}; StateIntegrity.__index=StateIntegrity
local function finite(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function add(errors,code,message) errors[#errors+1]={Code=code,Message=message} end
local function range(errors,code,name,v,lo,hi)
 if not finite(v) then add(errors,code,name.." is not finite") elseif v<lo or v>hi then add(errors,code,name.." out of range: "..tostring(v)) end
end
function StateIntegrity.new() return setmetatable({LastErrors={},TotalErrors=0,Checks=0},StateIntegrity) end
function StateIntegrity:Check(state)
 local x=state and state.Get and state:Get() or state; local errors={}
 if type(x)~="table" then add(errors,"STATE_MISSING","aircraft state is not a table"); self.LastErrors=errors; self.TotalErrors+=#errors; self.Checks+=1; return false,errors end
 range(errors,"ALTITUDE_INVALID","Altitude",x.Altitude,0,60000); range(errors,"AIRSPEED_INVALID","Airspeed",x.Airspeed,0,600); range(errors,"HEADING_INVALID","Heading",x.Heading,-720,720); range(errors,"PITCH_INVALID","Pitch",x.Pitch,-90,90); range(errors,"ROLL_INVALID","Roll",x.Roll,-180,180); range(errors,"VS_INVALID","VerticalSpeed",x.VerticalSpeed,-20000,20000); range(errors,"MASS_INVALID","Mass",x.Mass,0,300000); range(errors,"WEIGHT_INVALID","Weight",x.Weight,0,3000000)
 local engines=x.Engines
 if type(engines)~="table" then add(errors,"ENGINES_MISSING","engine state missing") else for i=1,2 do local e=engines[i]; if type(e)~="table" then add(errors,"ENGINE_MISSING","engine "..i.." state missing") else range(errors,"ENGINE_N1_INVALID","Engine"..i.." N1",e.N1,0,130); range(errors,"ENGINE_N2_INVALID","Engine"..i.." N2",e.N2,0,130); range(errors,"ENGINE_EGT_INVALID","Engine"..i.." EGT",e.EGT,-100,1500); range(errors,"ENGINE_THRUST_INVALID","Engine"..i.." Thrust",e.Thrust,0,300000) end end end
 local fuel=x.Fuel; if type(fuel)=="table" then for _,k in ipairs({"Left","Center","Right","Total"}) do range(errors,"FUEL_INVALID","Fuel."..k,fuel[k],0,1000000) end end
 local hydraulic=x.Hydraulic; if type(hydraulic)=="table" then for _,k in ipairs({"A","B","Standby"}) do local h=hydraulic[k]; if type(h)~="table" then add(errors,"HYDRAULIC_STATE_INVALID","Hydraulic."..k.." is not a table") else range(errors,"HYDRAULIC_PRESSURE_INVALID","Hydraulic."..k..".Pressure",h.Pressure,0,10000); range(errors,"HYDRAULIC_QUANTITY_INVALID","Hydraulic."..k..".Quantity",h.Quantity,0,100) end end else add(errors,"HYDRAULIC_MISSING","hydraulic state missing") end
 local gear=x.GearPosition; if type(gear)=="table" then for _,k in ipairs({"Nose","Left","Right"}) do range(errors,"GEAR_POSITION_INVALID","GearPosition."..k,gear[k],0,1) end end
 local nav=x.Navigation; if type(nav)=="table" then if type(nav.Route)~="table" then add(errors,"NAV_ROUTE_INVALID","Navigation.Route is not a table") end; local aw=tonumber(nav.ActiveWaypoint); if aw and (aw<1 or aw>math.max(1,#(nav.Route or {}))+1) then add(errors,"NAV_WAYPOINT_INVALID","ActiveWaypoint out of route bounds") end end
 local ap=x.Autopilot; if type(ap)=="table" then if ap.Enabled~=true and ap.Enabled~=false then add(errors,"AP_STATE_INVALID","Autopilot.Enabled is not boolean") end; range(errors,"AP_TARGET_ALT_INVALID","Autopilot.TargetAltitude",ap.TargetAltitude or 0,0,60000) end
 local press=x.Pressurization; if type(press)=="table" then range(errors,"CABIN_ALT_INVALID","Pressurization.CabinAltitudeFt",press.CabinAltitudeFt,-10000,60000); range(errors,"CABIN_DIFF_INVALID","Pressurization.DifferentialPsi",press.DifferentialPsi,0,20) end
 local bad=#errors>0; self.LastErrors=errors; self.TotalErrors+=#errors; self.Checks+=1; return not bad,errors
end
return StateIntegrity
