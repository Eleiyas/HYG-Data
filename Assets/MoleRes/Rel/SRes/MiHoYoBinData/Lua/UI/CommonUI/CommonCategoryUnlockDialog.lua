local M = G.Class("CommonCategoryUnlockDialog", G.UIWindow)
local base = G.UIWindow
local unlock_max_count_item_cls_name = "UI/CommonUI/CommonCategoryUnlockMaxCountItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonCategoryUnlockDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  UIUtil.set_active(self._obj_unlock_max_count.transform, false)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  local extra_data = self:get_extra_data()
  local level = extra_data ~= nil and extra_data.level or 0
  UIUtil.set_text(self._txt_lvnum, TextMapFormatUtil.FormatInteger(level))
  UIUtil.set_text_by_id(self._txt_title, "StarExpress_Hud_LevelUp_Title")
  self:_refresh_unlock_items(level)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_close ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_refresh_unlock_items(level)
  if self._max_count_item == nil then
    local go = UIUtil.load_prefab_set_parent(self._obj_unlock_max_count, self._trans_content)
    self._max_count_item = self:add_panel(unlock_max_count_item_cls_name, go.transform)
  end
  self._max_count_item:set_extra_data({level = level})
  self._max_count_item:refresh()
end

function M:_add_ui_listener()
  if self._btn_close ~= nil then
    self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

return M
