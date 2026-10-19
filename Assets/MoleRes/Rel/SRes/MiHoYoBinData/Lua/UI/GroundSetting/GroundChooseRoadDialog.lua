local M = G.Class("GroundChooseRoadDialog", G.UIWindow)
local base = G.UIWindow
local PANEL_CLS = "UI/GroundSetting/GroundChooseRoadPanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/GroundChooseRoadDialog"
  self.config.type = EUIType.Dialog
  self._panel = nil
end

function M:on_create()
  base.on_create(self)
  self._panel = self:add_panel(PANEL_CLS, self.trans)
  self:_bind_close_buttons()
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data()
  if self._panel then
    self._panel:setup(extra_data)
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:_bind_close_buttons()
  if not is_null(self._btn_bg) then
    self:bind_close_btn(self._btn_bg)
  end
  if not is_null(self._btn_back) then
    self:bind_close_btn(self._btn_back)
  end
end

function M:refresh_select_slot(index, cfg_id)
  if self._panel then
    self._panel:refresh_select_slot(index, cfg_id)
  end
end

function M:toggle_multi_select(cfg_id)
  if self._panel then
    self._panel:toggle_multi_select(cfg_id)
  end
end

function M:is_multi_selected(cfg_id)
  if self._panel then
    return self._panel:is_multi_selected(cfg_id)
  end
  return false
end

function M:on_select_pattern_set(set_id)
  if self._panel then
    self._panel:on_select_pattern_set(set_id)
  end
end

return M
