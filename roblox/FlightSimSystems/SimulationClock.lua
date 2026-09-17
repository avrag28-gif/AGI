-- FlightSim fixed-step simulation clock v0.2
-- Keeps simulation cadence deterministic while bounding catch-up work after frame stalls.
local SimulationClock={}; SimulationClock.__index=SimulationClock

local function finite(v,default)
 v=tonumber(v)
 if v and v==v and v>-math.huge and v<math.huge then return v end
 return default
end

function SimulationClock.new(step,maxSubsteps)
 local s=math.max(1e-6,finite(step,1/60)); local m=math.max(1,math.floor(finite(maxSubsteps,16)))
 return setmetatable({step=s,maxSubsteps=m,accumulator=0,totalDropped=0,lastSteps=0,lastDropped=0,lastFrameDt=0},SimulationClock)
end

function SimulationClock:Advance(frameDt)
 local dt=math.max(0,math.min(finite(frameDt,0),0.25))
 self.lastFrameDt=dt
 self.accumulator+=dt
 local steps=math.min(math.floor(self.accumulator/self.step),self.maxSubsteps)
 local simulated=steps*self.step
 self.accumulator-=simulated
 local dropped=0
 if self.accumulator>=self.step then
  dropped=self.accumulator-math.fmod(self.accumulator,self.step)
  self.accumulator=math.fmod(self.accumulator,self.step)
  self.totalDropped+=dropped
 end
 self.lastSteps=steps
 self.lastDropped=dropped
 return steps,self.step,dropped,dt
end

return SimulationClock
