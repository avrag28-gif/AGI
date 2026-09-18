-- Physical aircraft bridge v0.1
-- Optional adapter between authoritative simulation state and a Roblox aircraft Model.
-- The bridge never moves an anchored model and never assumes a specific asset layout.
local Bridge={}; Bridge.__index=Bridge

local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end

function Bridge.new(model,options)
 options=options or {}
 return setmetatable({
  model=model,
  rootName=options.rootName or "Primary",
  studsPerMeter=options.studsPerMeter or 3.571428571,
  enabled=options.enabled~=false,
  lastPosition=nil,
 },Bridge)
end

function Bridge:_root()
 if not self.model or not self.model:IsA("Model") then return nil end
 if self.model.PrimaryPart then return self.model.PrimaryPart end
 local named=self.model:FindFirstChild(self.rootName,true)
 if named and named:IsA("BasePart") then return named end
 local fallback=self.model:FindFirstChildWhichIsA("BasePart",true)
 if fallback then self.model.PrimaryPart=fallback end
 return fallback
end

function Bridge:Step(state)
 if not self.enabled or not state then return false,"disabled" end
 local root=self:_root()
 if not root then return false,"missing_root" end
 if root.Anchored then return false,"anchored_root" end
 local p=state.Position
 if typeof(p)~="Vector3" then return false,"invalid_position" end
 local heading=finite(state.Heading) and state.Heading or 0
 local pitch=finite(state.Pitch) and state.Pitch or 0
 local roll=finite(state.Roll) and state.Roll or 0
 local scale=self.studsPerMeter
 local target=CFrame.new(p*scale)*CFrame.Angles(math.rad(-pitch),math.rad(heading),math.rad(-roll))
 self.model:PivotTo(target)
 self.lastPosition=target
 return true
end

return Bridge