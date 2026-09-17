-- FlightSim landing gear / brake contract tests v0.5
-- Source-level tests; these are not Roblox runtime execution tests.
local LandingGear=require(script.Parent.LandingGear)
local Brakes=require(script.Parent.Brakes)
local Hydraulic=require(script.Parent.Hydraulic)
local function check(ok,msg) assert(ok,msg) end
local function state(data) return {data=data,Get=function(self)return self.data end} end
local function base()
 return {Airspeed=100,Engines={{Running=true},{Running=true}},Electrical={Bus1=true,Bus2=true},Hydraulic={A=1800,B=1800},Gear={Nose=true,Left=true,Right=true},GearPosition={Nose=0,Left=0,Right=0},GearStatus={},Brakes={Parking=false,BrakePressure=0,ToeBrake=0,AntiSkid=true},HydraulicDemand={LandingGear=0,Brakes=0,FlightControls=0}}
end
local function run()
 local s=state(base()); local gear=LandingGear.new(s); local brakes=Brakes.new(s); local hydraulic=Hydraulic.new(s,{HydraulicMax=3000})
 for _=1,12 do gear:Step(0.5) end
 check(s.data.GearStatus.DownLocked,"hydraulic gear extension must reach down lock")
 s.data.Gear={Nose=false,Left=false,Right=false}; gear:Step(0.5)
 check(not s.data.GearStatus.DownLocked and s.data.GearStatus.Transitioning,"gear retraction must leave the down-locked state before completion")
 for _=1,3 do gear:Step(0.5) end
 check(s.data.GearStatus.UpLocked,"hydraulic gear retraction must reach up lock")
 s.data.Hydraulic.A=0; s.data.Hydraulic.B=0; s.data.Gear={Nose=true,Left=true,Right=true}; gear:Step(1); check(s.data.GearStatus.UpLocked,"failed dual hydraulics must leave gear at its prior locked position")
 s.data.Hydraulic.A=1800; s.data.Hydraulic.B=0; s.data.Brakes.ToeBrake=1; brakes:Step(1/60); check(s.data.Brakes.BrakePressure>0,"toe brake must build pressure with one hydraulic source")
 check(s.data.HydraulicDemand.Brakes>0,"brake demand must propagate")
 hydraulic:Step(1/60); check(s.data.Hydraulic.A>0 and s.data.Hydraulic.B==0,"hydraulic A must remain available while failed/empty B remains unavailable")
 s.data.Brakes.ToeBrake=0; s.data.Brakes.Parking=true; brakes:Step(1/60); check(s.data.Brakes.ParkingApplied and s.data.Brakes.BrakePressure>0,"parking brake must command actual pressure when hydraulics are available")
 s.data.Hydraulic.A=0; s.data.Hydraulic.B=0; s.data.Brakes.Parking=false; s.data.Brakes.ToeBrake=1; brakes:Step(1); check(s.data.Brakes.BrakePressure<0.01,"brake pressure must decay toward zero when hydraulics are unavailable")
 return true
end
return {Run=run}
