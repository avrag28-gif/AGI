-- FlightSim hydraulic allocation regression test v0.1
-- Source-level/unit contract; not executed in Roblox Studio here.
local FlightControls=require(script.Parent.FlightControls)
local Hydraulic=require(script.Parent.Hydraulic)
local function check(ok,msg) assert(ok,msg) end
local function state()
 local d={Airspeed=140,GroundContact=false,Controls={Aileron=0,Elevator=0.8,Rudder=0,Flap=0},Autopilot={Enabled=false},FailureEffects={},TrimPitch=0,Hydraulic={A=3000,B=3000},HydraulicDemand={},Engines={[1]={Running=true},[2]={Running=true}},Electrical={Bus1=true,Bus2=true}}
 return {data=d,Get=function(self)return self.data end}
end
local function run()
 local s=state(); FlightControls.new(s):Step(1/60)
 local beforeA=s.data.HydraulicDemand.FlightControlsA; local beforeB=s.data.HydraulicDemand.FlightControlsB
 check(beforeA>beforeB,"elevator-dominant control load must preserve asymmetric A/B allocation")
 Hydraulic.new(s,{HydraulicMax=3000}):Step(1/60)
 check(s.data.HydraulicDemand.FlightControlsA==beforeA,"Hydraulic must not overwrite producer allocation")
 check(s.data.HydraulicDemand.FlightControlsB==beforeB,"Hydraulic must not overwrite producer allocation")
 check(s.data.HydraulicState.DemandA>s.data.HydraulicState.DemandB,"combined hydraulic demand must retain A/B asymmetry")
 return true
end
return {Run=run}
