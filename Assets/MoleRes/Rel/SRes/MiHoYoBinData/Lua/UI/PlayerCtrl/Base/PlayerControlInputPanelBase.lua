local M = G.Class("PlayerControlInputPanelBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._can_show_long_pick = true
  self.is_fishing = false
  self._show_tool_bar_btn = false
  self._show_pick = false
  self.all_element = {}
end

function M:on_create()
  base.on_create(self)
  self:init_all_element()
end

function M:on_enable()
  base.on_enable(self)
  self:refresh_ui_ctrl_mode()
  self:refresh()
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

function M:update(deltaTime)
  if not self.is_active then
    return
  end
  for _, panel in pairs(self.container) do
    if panel.is_active and panel.update then
      panel:update(deltaTime)
    end
  end
  if self._need_refresh then
    self:inner_refresh()
    self._need_refresh = false
  end
end

function M:set_first_sibling()
  self.trans:SetAsFirstSibling()
end

function M:set_last_sibling()
  self.trans:SetAsLastSibling()
end

function M:refresh()
  self._need_refresh = true
end

function M:init_all_element()
end

function M:update_shortcut_pressed_state(common_btns)
  for key, tip in pairs(self.all_element) do
    if tip and tip.update_shortcut_pressed_state and tip.is_active then
      tip:update_shortcut_pressed_state(common_btns)
    end
  end
end

function M:refresh_ui_ctrl_mode()
  for key, tip in pairs(self.all_element) do
    if tip then
      tip:refresh_active()
    end
  end
  self:inner_refresh()
end

function M:inner_refresh()
end

function M:refresh_all_element()
  for key, tip in pairs(self.all_element) do
    if tip then
      tip:refresh()
    end
  end
end

return M
