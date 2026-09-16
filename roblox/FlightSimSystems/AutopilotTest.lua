-- FlightSim autopilot contract-test helpers v0.2
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local AutopilotTest={}
local function range(v,a,b,msg) v=tonumber(v) or 0; assert(v>=a and v<=b,msg) end
function AutopilotTest.ValidateCommands(state)
 local x=state:Get(); local ap=x.Autopilot or {}
 range(ap.CommandBank,-1,1,"autopilot bank command out of range")
 range(ap.CommandPitch,-1,1,"autopilot pitch command out of range")
 range(ap.CommandAileron,-1,1,"autopilot aileron command out of range")
 range(ap.CommandElevator,-1,1,"autopilot elevator command out of range")
 return true
end
function AutopilotTest.ValidateModeConsistency(state)
 local x=state:Get(); local ap=x.Autopilot or {}; local nav=x.Navigation or {}; local v=x.VNAV or {}
 if ap.Enabled then assert(ap.Mode~="OFF","enabled autopilot cannot report OFF") end
 if ap.Mode=="LNAV" then assert(nav.Mode=="LNAV","LNAV mode not reflected in navigation") end
 if ap.Mode=="VNAV" then assert(v.Mode=="VNAV","VNAV mode not reflected in VNAV state") end
 if ap.Mode=="APP_LOC" or ap.Mode=="APP_GS" or ap.Mode=="APP_ARMED" then assert(nav.Mode=="APP","approach mode not reflected in navigation") end
 if ap.Mode=="GO_AROUND" then assert(nav.Mode=="HDG","go-around must leave approach navigation mode") end
 return true
end
function AutopilotTest.ValidateCaptureFlags(state)
 local x=state:Get(); local ap=x.Autopilot or {}
 if ap.ILSGlideSlopeCaptured==true then assert(ap.ILSLocalizerCaptured==true,"glideslope captured without localizer capture") end
 if ap.Mode=="GO_AROUND" then assert(ap.ILSLocalizerCaptured~=true,"go-around retained localizer capture") end
 return true
end
function AutopilotTest.ValidateAll(state)
 AutopilotTest.ValidateCommands(state); AutopilotTest.ValidateModeConsistency(state); AutopilotTest.ValidateCaptureFlags(state); return true
end
return AutopilotTest
