-- FlightSim approach/ILS contract-test helpers v0.1
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
 return true
end
function ApproachTest.ValidateCaptureDependency(state)
 local i=(state:Get().Navigation or {}).ILS
 if i and i.GlideSlopeCaptured then assert(i.LocalizerCaptured==true,"glide-slope cannot be captured before localizer") end
 return true
end
function ApproachTest.ValidateAll(state)
 ApproachTest.Validate(state); ApproachTest.ValidateCaptureDependency(state); return true
end
return ApproachTest
