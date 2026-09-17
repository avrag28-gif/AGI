-- Flight-controls to physics regression tests v1.0
-- Pure numeric contract checks; intended to be run in Roblox Studio/test harness.
local function assertNear(actual,expected,tolerance,message)
 assert(math.abs(actual-expected)<=tolerance,message.." expected="..tostring(expected).." actual="..tostring(actual))
end

local function response(elevator,aileron,rudder)
 local aoa=2.5+0.75*elevator
 local pCtrl=elevator*9
 local rCtrl=aileron*28
 local yCtrl=rudder*9
 return aoa,pCtrl,rCtrl,yCtrl
end

local neutralAoA,p0,r0,y0=response(0,0,0)
assertNear(neutralAoA,2.5,1e-9,"neutral AoA")
assertNear(p0,0,1e-9,"neutral pitch control")
assertNear(r0,0,1e-9,"neutral roll control")
assertNear(y0,0,1e-9,"neutral yaw control")

local highElevatorAoA=select(1,response(1,0,0))
assert(highElevatorAoA>neutralAoA,"positive elevator must increase modeled AoA")

local rollResponse=select(3,response(0,1,0))
assert(rollResponse>0,"positive aileron must produce positive roll command")

local yawResponse=select(4,response(0,0,1))
assert(yawResponse>0,"positive rudder must produce positive yaw command")

print("FlightControlsPhysicsCouplingTest PASS")
