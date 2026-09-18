-- Cockpit/control contract regression tests v0.1
local State=require(script.Parent.State)
local Test={}
local function check(ok,msg) if not ok then error(msg,2) end end
function Test.Run()
 local x=State.new()
 check(type(x.MCP)=="table","MCP state contract missing")
 check(type(x.TrimPitch)=="number","trim pitch state missing")
 check(type(x.Controls)=="table" and type(x.Controls.Trim)=="number","trim control contract missing")
 check(type(x.FlapSystem)=="table","flap system state missing")
 check(type(x.GearStatus)=="table","gear status contract missing")
 check(type(x.GearPosition)=="table","gear position contract missing")
 check(type(x.Annunciation)=="table","annunciation state contract missing")
 x.MCP.Heading=180; x.MCP.Altitude=12000; x.MCP.Speed=210; x.MCP.VerticalSpeed=700
 x.Controls.Trim=0.25; x.TrimPitch=2.5; x.FlapSystem.Detent=10; x.FlapSystem.OverSpeed=true
 x.GearStatus.DownLocked=false; x.GearStatus.Transitioning=true; x.Annunciation.MasterWarning=true
 check(x.MCP.Heading==180 and x.MCP.Altitude==12000,"MCP values were not retained")
 check(x.Controls.Trim==0.25 and x.TrimPitch==2.5,"trim values were not retained")
 check(x.FlapSystem.Detent==10 and x.FlapSystem.OverSpeed==true,"flap indication state was not retained")
 check(x.GearStatus.Transitioning==true and x.GearStatus.DownLocked==false,"gear indication state was not retained")
 check(x.Annunciation.MasterWarning==true,"annunciation state was not retained")
 return true
end
return Test
