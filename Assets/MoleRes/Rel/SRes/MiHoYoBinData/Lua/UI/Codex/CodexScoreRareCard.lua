local M = G.Class("CodexScoreRareCard", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreRareCard"
  self._on_complete = nil
  self._rare_data_list = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_tap))
  end
end

function M:show(rare_data_list, on_complete)
  self._rare_data_list = rare_data_list
  self._on_complete = on_complete
  self:set_active(true)
  UIUtil.set_active(self.trans, true)
end

function M:hide()
  self:set_active(false)
  UIUtil.set_active(self.trans, false)
end

function M:_on_tap()
  local cb = self._on_complete
  self._on_complete = nil
  self:hide()
  if cb then
    cb()
  end
end

return M
