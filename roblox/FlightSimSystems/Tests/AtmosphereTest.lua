-- Shared atmosphere regression tests
local Atmosphere=require(script.Parent.Parent.Atmosphere)
local function near(a,b,tol) assert(math.abs(a-b)<=tol,string.format("expected %.6f ~= %.6f",a,b)) end
local sea=Atmosphere.State(0,nil)
near(sea.TemperatureC,15,0.01)
near(sea.DensityKgM3,1.225,0.02)
local cruise=Atmosphere.State(35000,nil)
assert(cruise.DensityKgM3<sea.DensityKgM3,"cruise density must be below sea-level density")
assert(cruise.SpeedOfSoundKts<sea.SpeedOfSoundKts,"speed of sound must decrease with colder high-altitude ISA")
local hot=Atmosphere.State(0,35)
assert(hot.DensityKgM3<sea.DensityKgM3,"hot air must be less dense at the same pressure altitude")
near(Atmosphere.ISATemperatureC(41000),-56.5,0.1)
local mach=Atmosphere.MachFromKts(340,35000,nil)
assert(mach>0.5 and mach<0.8,"340 kt at 35000 ft should produce a finite subsonic Mach")
return true
