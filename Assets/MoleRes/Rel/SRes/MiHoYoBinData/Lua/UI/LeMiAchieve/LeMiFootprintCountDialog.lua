local M = G.Class("LeMiFootprintCountDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LeMiAchieve/LeMiFootprintCountDialog"
  self.config.type = EUIType.Dialog
  self._cur_index = 1
  self._category_list = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._category_list = self:_build_category_list()
  self._cur_index = 1
  local extra_data = self:get_extra_data()
  if extra_data and extra_data.category then
    local idx = self:_index_of_category(extra_data.category)
    if idx then
      self._cur_index = idx
    end
  end
  self:_refresh_category()
end

function M:on_disable()
  base.on_disable(self)
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

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_close_btn(self._btn_bg_close, true)
  self:bind_callback(self._btn_arrow_left, pack(self, M._on_btn_arrow_left_click))
  self:bind_callback(self._btn_arrow_right, pack(self, M._on_btn_arrow_right_click))
end

function M:_on_btn_arrow_left_click()
  if self._cur_index <= 1 then
    return
  end
  self._cur_index = self._cur_index - 1
  self:_refresh_category()
end

function M:_on_btn_arrow_right_click()
  if self._cur_index >= self:_get_category_count() then
    return
  end
  self._cur_index = self._cur_index + 1
  self:_refresh_category()
end

function M:_refresh_category()
  local category = self:_get_cur_category()
  if category == nil then
    return
  end
  local cfg = ExcelDataUtil.get_value(typeof(BBehaviorInfoCfg), category)
  if cfg then
    UIUtil.set_text_by_id(self._txt_title, cfg.titletext)
    UIUtil.set_text_by_id(self._text_category, cfg.titletext)
    UIUtil.set_image(self._img_left_show, cfg.icon, self:get_load_proxy())
    UIUtil.set_text_by_id(self._text_include_list, cfg.contenttext)
  end
  local type_data = le_mi_achievement_module:get_foot_step_type_distance(category)
  local is_slow = type_data and type_data.IsSlow or false
  self._state_income:SetState(is_slow and 1 or 0)
  local count = self:_get_category_count()
  UIUtil.set_text(self._text_num, string.format("%d/%d", self._cur_index, count))
  self:_refresh_arrow_state(count)
end

function M:_build_category_list()
  return le_mi_achievement_module:get_behavior_category_list()
end

function M:_refresh_arrow_state(count)
  self._btn_arrow_left.interactable = self._cur_index > 1
  self._btn_arrow_right.interactable = count > self._cur_index
end

function M:_get_category_count()
  return self._category_list and #self._category_list or 0
end

function M:_get_cur_category()
  if self._category_list == nil then
    return nil
  end
  return self._category_list[self._cur_index]
end

function M:_index_of_category(category)
  if self._category_list == nil then
    return nil
  end
  for i, v in ipairs(self._category_list) do
    if v == category then
      return i
    end
  end
  return nil
end

return M
