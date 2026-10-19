local M = G.Class("NpcClothGiftInfoItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
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

function M:refresh(npc_id)
  if not npc_id or npc_id <= 0 then
    return
  end
  npc_module:set_npc_icon_by_id(self._img_npc_icon_common, npc_id, self:get_load_proxy())
  UIUtil.set_active(self._txt_npc_name, false)
  npc_favour_module:set_favor_level_display(npc_id, self._ui_state_max_group, self._txt_favor_level_common)
  self._ui_state_common_group:SetState(0)
end

return M
