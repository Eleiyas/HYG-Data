local M = G.Class("ChefLevelItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnChefLevelDataNotify, function()
    self:refresh()
  end)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_click, pack(self, M._on_btn_click_click))
end

function M:_on_btn_click_click()
  cooking_module:open_chef_level_award_page()
end

function M:refresh()
  local level = CsCookModuleUtil.GetChefLevel() or 0
  local total_exp = CsCookModuleUtil.GetChefLevelExp() or 0
  local cfg = ExcelDataUtil.get_value(typeof(BChefLevelCfg), level)
  UIUtil.set_text(self._txt_lv, tostring(level))
  if not is_null(cfg) then
    if not_null(self._txt_name) then
      UIUtil.set_text(self._txt_name, cfg.cheftitle or "")
    end
    if not_null(self._img_icon) and string.is_valid(cfg.cheftitleicon) then
      UIUtil.set_image(self._img_icon, cfg.cheftitleicon, self:get_load_proxy())
    end
  end
  if not_null(self._slider) then
    self._slider.minValue = 0
    self._slider.maxValue = 1
    self._slider.value = cooking_module:get_chef_level_exp_progress(level, total_exp)
  end
  self:_refresh_redpoint()
end

function M:_refresh_redpoint()
  if is_null(self._redpoint) then
    return
  end
  local show = cooking_module:has_any_claimable_chef_level_reward()
  self._redpoint:ShowRedPoint(show and RedPointType.GiftRP or RedPointType.None)
end

return M
