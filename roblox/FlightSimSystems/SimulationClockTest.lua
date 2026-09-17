-- Fixed-step simulation clock regression tests v0.1
local Clock=require(script.Parent.SimulationClock)
local function check(ok,msg) assert(ok,msg) end
local function run()
 local c=Clock.new(1/60,16)
 local steps,step,dropped=c:Advance(1/30)
 check(steps==2,"30 Hz frame must execute two 60 Hz simulation steps")
 check(math.abs(step-1/60)<1e-9,"fixed step must remain 60 Hz")
 check(dropped==0,"normal catch-up must not drop simulation time")
 steps,_,dropped=c:Advance(0.25)
 check(steps==15,"250 ms frame must execute all required 60 Hz steps within the bounded frame budget")
 check(dropped==0,"250 ms frame must not drop simulation time with 16-step budget")
 steps,_,dropped=c:Advance(1.0)
 check(steps==15,"large frame delta must be capped before simulation catch-up")
 check(dropped==0,"capped 1 second frame must not create unbounded catch-up")
 check(c.totalDropped==0,"normal bounded frames must not report dropped simulation time")
 return true
end
return {Run=run}
