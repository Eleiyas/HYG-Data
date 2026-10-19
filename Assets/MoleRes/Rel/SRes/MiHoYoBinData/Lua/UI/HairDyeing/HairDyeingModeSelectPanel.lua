local M = G.Class("HairDyeingModeSelectPanel", G.UIPanel)
local base = G.UIPanel
local coin_item_cls = common_ui_module.common_coin_item_view_cls

function M:init()
  base.init(self)
  self.config.prefab_path = hair_dyeing_module.ui_prefab_path.mode_select
  self._on_mode_selected = nil
  self._on_close = nil
  self._coin_item = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_flower, pack(self, M._on_btn_flower))
  self:bind_callback(self._btn_dye, pack(self, M._on_btn_dye))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help))
end

function M:register_events()
  base.register_events(self)
end

function M:set_on_mode_selected(callback)
  self._on_mode_selected = callback
end

function M:set_on_close(callback)
  self._on_close = callback
end

function M:_on_btn_flower()
  self:_select(hair_dyeing_module.dye_mode.flower)
end

function M:_on_btn_dye()
  self:_select(hair_dyeing_module.dye_mode.dye)
end

function M:_select(mode)
  if self._on_mode_selected then
    self._on_mode_selected(mode)
  end
end

function M:_on_btn_close()
  if self._on_close then
    self._on_close()
  end
end

function M:_on_btn_help()
  UIManagerInstance:open("UI/CommonUI/IntroductionDialog", 31)
end

return M
