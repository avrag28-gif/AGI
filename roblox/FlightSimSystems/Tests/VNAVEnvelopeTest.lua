-- VNAV envelope guidance regression test v1.0
local VNAV=require(script.Parent.Parent.VNAV)
local function expect(name,condition)
 if not condition then error("VNAVEnvelopeTest failed: "..name,2) end
end
local function makeState(data)
 local state={data=data}
 function state:Get() return self.data end
 return state
end
local base={
 Altitude=30000,Airspeed=250,IndicatedAirspeed=250,
 Navigation={Mode="LNAV",ActiveWaypoint=1,DistanceToWaypoint=50000,Route={{Altitude=20000,AltitudeConstraint="AT",Position=Vector3.new(0,0,0)}}},
 Autopilot={TargetAltitude=20000,TargetSpeed=250},FMC={},
 VNAV={Mode="VNAV"},FlightEnvelope={StallMarginKt=20,Overspeed=false}
}
local s1=makeState(base); local c1=VNAV.new(s1); c1:Step(1/60); expect("normal guidance",s1:Get().VNAV.CommandVerticalSpeed<0)
local stall=table.clone(base); stall.FlightEnvelope={StallMarginKt=-10,Overspeed=false}; stall.VNAV={Mode="VNAV"}
local s2=makeState(stall); local c2=VNAV.new(s2); c2:Step(1/60); expect("stall limits descent",s2:Get().VNAV.CommandVerticalSpeed>=-500); expect("stall reason",s2:Get().VNAV.LimitReason=="STALL_MARGIN")
local over=table.clone(base); over.FlightEnvelope={StallMarginKt=20,Overspeed=true}; over.VNAV={Mode="VNAV"}
local s3=makeState(over); local c3=VNAV.new(s3); c3:Step(1/60); expect("overspeed limits climb",s3:Get().VNAV.CommandVerticalSpeed<=500); expect("overspeed reason",s3:Get().VNAV.LimitReason=="OVERSPEED")
return true
