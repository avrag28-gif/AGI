-- Avionics electrical load-shed regression test v0.1
local State=require(script.Parent.State)
local Avionics=require(script.Parent.Avionics)
local Test={}
local function check(c,m) if not c then error(m,2) end end
local function base()
 local s=State.new(); local x=s:Get()
 x.Electrical.Bus1=true; x.Electrical.Bus2=true
 x.ElectricalState.LoadShed={NonEssential=false,Display=false,Avionics=false}
 x.Avionics.WeatherRadarEnabled=true
 return s
end
function Test.Run()
 local s=base(); Avionics.new(s):Step(0.1); local a=s:Get().Avionics
 check(a.IRS and a.FMC and a.Radios and a.Transponder and a.TCAS and a.WeatherRadar,"dual-bus avionics did not power correctly")
 s:Get().Electrical.Bus1=false; s:Get().Electrical.Bus2=false
 s:Get().ElectricalState.LoadShed={NonEssential=true,Display=true,Avionics=true}
 Avionics.new(s):Step(0.1); a=s:Get().Avionics
 check(not a.IRS and not a.FMC and not a.Radios and not a.Transponder and not a.TCAS and not a.WeatherRadar,"avionics remained powered during total bus loss")
 s=base(); s:Get().Electrical.Bus2=false; s:Get().ElectricalState.LoadShed={NonEssential=true,Display=true,Avionics=false}
 Avionics.new(s):Step(0.1); a=s:Get().Avionics
 check(a.FMC and a.Radios and a.Transponder and a.TCAS,"single-bus operation incorrectly shed essential avionics")
 return true
end
return Test
