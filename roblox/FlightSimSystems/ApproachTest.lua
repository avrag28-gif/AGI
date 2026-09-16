-- FlightSim approach/ILS contract-test helpers v0.2
-- Deterministic state-level checks. These helpers do not run Roblox physics.
local ApproachTest={}
local function range(v,a,b,msg) v=tonumber(v) or 0; assert(v>=a and v<=b,msg) end
function ApproachTest.Validate(state)
 local x=state:Get(); local n=x.Navigation or {}; local i=n.ILS
 if not i then return true end
 range(i.Localizer,-1,1,"localizer out of range")
 range(i.GlideSlope,-1,1,"glide-slope error out of range")
 assert((tonumber(i.Distance) or -1)>=0,"ILS distance invalid")
 assert(type(i.LocalizerValid)=="boolean","localizer validity invalid")
 assert(type(i.GlideSlopeValid)=="boolean","glide-slope validity invalid")
 assert(type(i.LocalizerCaptured)=="boolean","localizer capture state invalid")
 assert(type(i.GlideSlopeCaptured)=="boolean","glide-slope capture state invalid")
 if i.RequiredFrequency~=nil then
  local f=tonumber(i.RequiredFrequency); assert(f and f>=108 and f<=117.95,"required ILS frequency invalid")
 end
 if i.TunedFrequency~=nil then assert(tonumber(i.TunedFrequency)~=nil,"tuned NAV1 frequency invalid") end
 return true
end
function ApproachTest.ValidateReceiver(state)
 local i=(state:Get().Navigation or {}).ILS
 if not i then return true end
 if i.Available==false then
  assert(i.LocalizerValid==false,"ILS receiver unavailable but localizer is valid")
  assert(i.GlideSlopeValid==false,"ILS receiver unavailable but glideslope is valid")
  assert(i.LocalizerCaptured==false,"ILS receiver unavailable but localizer is captured")
  assert(i.GlideSlopeCaptured==false,"ILS receiver unavailable but glideslope is captured")
 end
 return true
end
function ApproachTest.ValidateCaptureDependency(state)
 local i=(state:Get().Navigation or {}).ILS
 if i and i.GlideSlopeCaptured then assert(i.LocalizerCaptured==true,"glide-slope cannot be captured before localizer") end
 return true
end
function ApproachTest.ValidateAll(state)
 ApproachTest.Validate(state); ApproachTest.ValidateReceiver(state); ApproachTest.ValidateCaptureDependency(state); return true
end
return ApproachTest
