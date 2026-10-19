local M = G.Class("DetailPanelComponentBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
  self.parent = self.trans.parent
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
end

function M:refresh(data)
end

function M:show()
  self:set_active(true)
end

function M:hide()
  self:set_active(false)
end

function M:set_type(type)
  self.type = type
end

function M:check_parent_and_sort(trans_parent)
  if self.parent == nil or self.parent:GetInstanceID() ~= trans_parent:GetInstanceID() then
    self.trans:SetParent(trans_parent)
    self.parent = trans_parent
  end
  self.trans:SetAsLastSibling()
end

return M
