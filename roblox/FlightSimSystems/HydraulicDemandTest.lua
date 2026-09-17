-- FlightSim hydraulic demand ownership test v0.1
-- Source-level test only; no Roblox Studio runtime execution is claimed.
local Hydraulic=require(script.Parent.Hydraulic)
local function check(ok,msg) assert(ok,msg) end
local function state(data)
 return {data=data,Get=function(self)return self.data end}
end
local function run()
 local cfg={HydraulicMax=3000}
 local x=state({Hydraulic={A=3000,B=3000},HydraulicDemand={FlightControls=0.8,A=0.8,B=0.2,LandingGear=0.7,Brakes=0.1},Failures={Hydraulic={}},Engines={[1]={Running=true},[2]={Running=true}},Electrical={Bus1=true,Bus2=true}})
 Hydraulic.new(x,cfg):Step(1/60)
 check(x.data.HydraulicDemand.A>=0.8,"hydraulic must preserve FlightControls A demand")
 check(x.data.HydraulicDemand.B>=0.2,"hydraulic must preserve FlightControls B demand")
 local y=state({Hydraulic={A=3000,B=3000},HydraulicDemand={FlightControls=0,A=0.9,B=0.1,LandingGear=0,Brakes=0},Failures={Hydraulic={}},Engines={[1]={Running=true},[2]={Running=true}},Electrical={Bus1=true,Bus2=true}})
 Hydraulic.new(y,cfg):Step(1/60)
 check(y.data.HydraulicDemand.A>=0.9 and y.data.HydraulicDemand.B>=0.1,"asymmetric flight-control demand must survive hydraulic aggregation")
 return true
end
return {Run=run}
