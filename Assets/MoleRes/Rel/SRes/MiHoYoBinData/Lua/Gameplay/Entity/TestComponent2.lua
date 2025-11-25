require("Gameplay.BaseComponent")
TestComponent2 = BaseComponent:new()

function TestComponent2:registerEvents()
  Logger.Log("TestComponent2 registerEvents")
  self._events[EventID.luaShowNetError] = pack(self, TestComponent2.OnShowNetError)
end

function TestComponent2:OnInteract(num)
  Logger.Log("TestComponent2 OnInteract owner " .. self.owner.root.name)
  Logger.Log("TestComponent2 OnInteract " .. num)
end

function TestComponent2:OnShowNetError(str)
  Logger.Log("TestComponent2 OnShowNetError " .. tostring(str))
end

function TestComponent2:on_init()
  Logger.Log("TestComponent2 on_init")
end

function TestComponent2:on_entity_ready()
  Logger.Log("TestComponent2 on_entity_ready " .. self.owner.root.name)
  if not self.loadCount then
    self.loadCount = 1
  else
    self.loadCount = self.loadCount + 1
  end
  if not G.count then
    G.count = 1
  else
    G.count = G.count + 1
  end
  Logger.Log("TestComponent2 on_entity_ready " .. self.owner.root.name .. " Self.LoadCount = " .. self.loadCount .. " G.count :: " .. G.count)
end

function TestComponent2:on_other_component_ready()
  Logger.Log("TestComponent2 on_other_component_ready")
end

function TestComponent2:on_remove_entity()
  Logger.Log("TestComponent2 on_remove_entity")
end

function TestComponent2:update()
end

function TestComponent2:late_update()
end

function TestComponent2:tick_before_release()
  Logger.Log("TestComponent2 tick_before_release ")
end

function TestComponent2:on_apply_new_data()
  Logger.Log("TestComponent2 on_apply_new_data ")
end

function TestComponent2:on_delay_remove()
  G.count = G.count - 1
  Logger.Log("TestComponent2 on_delay_remove " .. G.count)
end

function TestComponent2:can_release()
  Logger.Log("TestComponent2 can_release ")
  return true
end

return TestComponent2
