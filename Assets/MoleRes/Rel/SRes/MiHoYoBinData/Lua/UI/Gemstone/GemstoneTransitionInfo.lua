local M = G.Class("GemstoneTransitionInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Gemstone/GemstoneTransitionInfo"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_bg, function()
    self:close_self(true)
  end)
end

function M:on_open()
  base.on_open(self)
  self._can_close = false
  self._item_id = self._extra_data.itemId or 0
  self._item_id_before = self._extra_data.itemIdBefore or 0
  self._transition_type = self._extra_data.type or 0
  self._on_complete = self._extra_data.onComplete
  self:_refresh_ui()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  if self._on_complete then
    self._on_complete()
    self._on_complete = nil
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_ui()
  local item_cfg, item_cfg_before
  if self._item_id > 0 then
    item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), self._item_id)
  end
  if 0 < self._item_id_before then
    item_cfg_before = ExcelDataUtil.get_value(typeof(BItemCfg), self._item_id_before)
  end
  if not is_null(item_cfg_before) then
    UIUtil.set_image(self._img_icon_before, item_cfg_before.icon, self:get_load_proxy())
  end
  if not is_null(item_cfg) then
    UIUtil.set_image(self._img_icon, item_cfg.icon, self:get_load_proxy())
    UIUtil.set_text(self._txt_name, item_cfg.name)
  else
    UIUtil.set_text(self._txt_name, "")
  end
  if self._state_group then
    self._state_group:SetState(self._transition_type)
  end
end

return M
