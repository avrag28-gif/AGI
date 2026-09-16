-- FlightSim ATC sequencing contract tests v0.2
local ATCTraffic=require(script.Parent.ATCTraffic)
local ATCSequencer=require(script.Parent.ATCSequencer)
local Test={}
local function check(c,m) if not c then error(m,2) end end
function Test.Run()
 local traffic=ATCTraffic.new(); traffic:RegisterRunway("27")
 local seq=ATCSequencer.new(traffic)
 local ok,e=seq:Enqueue("27","AC1","FS1001","TAKEOFF"); check(ok and e.Sequence==1,"first enqueue failed")
 ok,e=seq:Enqueue("27","AC2","FS1002","TAKEOFF"); check(ok and e.Sequence==2,"second enqueue failed")
 check(seq:QueueLength("27")==2,"queue length incorrect")
 local allowed,reason=seq:CanProceed("27","AC2"); check(not allowed and reason=="not_next_in_sequence","second aircraft bypassed queue")
 ok,e=seq:GrantNext("27"); check(ok and e.AircraftId=="AC1" and e.State=="RESERVED","first reservation failed")
 check(seq:QueueLength("27")==1,"queue did not advance")
 allowed,reason=seq:GrantNext("27"); check(not allowed and reason=="runway_reserved","occupied reservation was bypassed")
 traffic:Release("27","AC1")
 ok,e=seq:GrantNext("27"); check(ok and e.AircraftId=="AC2","second reservation failed")
 check(seq:QueueLength("27")==0,"second queue entry was not consumed")
 check(not seq:Enqueue("27","AC2","FS1002","TAKEOFF"),"duplicate occupied aircraft accepted")
 check(not seq:Enqueue("27","AC2","FS1002","LANDING"),"same occupied aircraft accepted under another operation")
 traffic:Release("27","AC2")
 ok,e=seq:Enqueue("27","AC2","FS1002","LANDING"); check(ok,"released aircraft could not be queued again")
 return true
end
return Test
