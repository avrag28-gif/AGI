-- FlightSim transponder system v0.1
local Transponder={}; Transponder.__index=Transponder
local MODES={STBY=true,ON=true,ALT=true}
local function validCode(code) return type(code)=="string" and code:match("^[0-7][0-7][0-7][0-7]$")~=nil end
function Transponder.new(state) return setmetatable({state=state},Transponder) end
function Transponder:Step(dt)
	local x=self.state:Get(); x.Transponder=x.Transponder or {Code="2000",Mode="STBY",Ident=false}
	local t=x.Transponder
	if not validCode(t.Code) then t.Code="2000" end
	if not MODES[t.Mode] then t.Mode="STBY" end
	if t.IdentUntil and os.clock()>=t.IdentUntil then t.Ident=false; t.IdentUntil=nil end
end
function Transponder:SetCode(code)
	code=tostring(code); if not validCode(code) then return false,"invalid_transponder" end
	self.state:Get().Transponder.Code=code; return true
end
function Transponder:SetMode(mode)
	mode=string.upper(tostring(mode)); if not MODES[mode] then return false,"invalid_transponder_mode" end
	self.state:Get().Transponder.Mode=mode; return true
end
function Transponder:Ident()
	local t=self.state:Get().Transponder; t.Ident=true; t.IdentUntil=os.clock()+18; return true
end
return Transponder
