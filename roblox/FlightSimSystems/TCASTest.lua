-- FlightSim TCAS contract tests v0.1
-- Source-level deterministic contract for power gating, stale clearing, ordering, and motion-aware advisories.
local TCAS=require(script.Parent["TCAS.v02"])
local function check(v,m) assert(v,m) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function registry(items)
 return {items=items,Get=function(self,id)return self.items[id] end,ForEach=function(self,fn)for id,s in pairs(self.items)do fn(id,s)end end}
end
local function run()
 local own=state({Position=Vector3.new(0,0,0),Altitude=10000,Velocity=Vector3.new(100,0,0),Avionics={TCAS=true},TCAS={}})
 local near=state({Position=Vector3.new(1000,0,0),Altitude=10200,Velocity=Vector3.new(-50,0,0)})
 local far=state({Position=Vector3.new(12000,0,0),Altitude=10000,Velocity=Vector3.new(0,0,0)})
 local r=registry({OWN=own,NEAR=near,FAR=far}); local t=TCAS.new(r); local a=t:Step("OWN")
 check(#a==1,"far non-threat traffic should not create advisory")
 check(a[1].Intruder=="NEAR","nearest threat must be retained")
 check(a[1].RangeM>0 and a[1].RangeNm>0,"range conversion missing")
 check(a[1].ClosingSpeedKts>0,"closing speed must be derived from relative velocity")
 check(own.data.TCAS.ClosestIntruder=="NEAR","closest intruder not propagated")
 check(own.data.TCAS.HighestLevel=="RA" or own.data.TCAS.HighestLevel=="TA","highest advisory missing")
 own.data.Avionics.TCAS=false; t:Step("OWN"); check(#own.data.TCAS.Advisories==0 and own.data.TCAS.ClosestIntruder==nil and own.data.TCAS.ClosestRangeM==nil and own.data.TCAS.HighestLevel=="NONE","power-off state was not cleared")
 own.data.Avionics.TCAS=true; near.data.Position=Vector3.new(0,0,10000); near.data.Altitude=12000; near.data.Velocity=Vector3.new(0,0,0); t:Step("OWN"); check(#own.data.TCAS.Advisories==0,"vertical separation outside envelope should not alert")
 return true
end
return {Run=run}
