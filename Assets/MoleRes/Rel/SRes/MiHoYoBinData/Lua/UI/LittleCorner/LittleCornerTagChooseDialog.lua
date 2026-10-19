local M = G.Class("LittleCornerTagChooseDialog", G.UIWindow)
local base = G.UIWindow
local group_item_cls = "UI/LittleCorner/LittleCornerTagChooseGroupItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerTagChooseDialog"
  self.config.type = EUIType.Dialog
  self._btn_close_popup = nil
  self._btn_confirm = nil
  self._txt_choosed_tag_num = nil
  self._btn_bg = nil
  self._list_item_binder = nil
  self._btn_reset = nil
  self._group_items = {}
  self._selected_tags = {}
  self._custom_on_confirm = nil
  self._max_tag_count = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
  self._selected_tags = {}
  local extra_data = self:get_extra_data()
  if extra_data and type(extra_data) == "table" then
    self._custom_on_confirm = extra_data.on_confirm
    self._max_tag_count = extra_data.max_tag_count
  else
    self._custom_on_confirm = nil
    self._max_tag_count = nil
  end
  local default_tags = extra_data and extra_data.default_tags
  if default_tags then
    for _, tag_id in ipairs(default_tags) do
      self._selected_tags[tag_id] = true
    end
  end
  self:_init_tag_groups()
  self:_refresh_selected_count()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._selected_tags = {}
  self._custom_on_confirm = nil
  self._max_tag_count = nil
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_bg)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close_popup, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  self:bind_callback(self._btn_reset, pack(self, M._on_btn_reset_click))
end

function M:_init_tag_groups()
  local all_groups = ExcelDataUtil.get_table(typeof(CS.miHoYo.HYG.ExcelData.BXhsTagGroupCfg)) or {}
  local sorted_groups = {}
  for _, group_cfg in pairs(all_groups) do
    table.insert(sorted_groups, group_cfg)
  end
  table.sort(sorted_groups, function(a, b)
    return a.id < b.id
  end)
  local index = 0
  for _, group_cfg in ipairs(sorted_groups) do
    index = index + 1
    local item = self._group_items[index]
    if not item then
      local obj = self._list_item_binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(group_item_cls, obj, {group_cfg = group_cfg, dialog = self})
        self._group_items[index] = item
        UIUtil.set_active(obj, true)
      end
    else
      item:set_extra_data({group_cfg = group_cfg, dialog = self})
      item:_refresh_ui()
      UIUtil.set_active(item.game_obj, true)
    end
  end
  for i = index + 1, #self._group_items do
    if self._group_items[i] then
      UIUtil.set_active(self._group_items[i].game_obj, false)
    end
  end
end

function M:_refresh_selected_count()
  local count = 0
  for _, _ in pairs(self._selected_tags) do
    count = count + 1
  end
  local max_count = self._max_tag_count or little_corner_module.max_choose_tag_count
  UIUtil.set_text(self._txt_choosed_tag_num, string.format("%s%d/%d", UIUtil.get_text_by_id("Xhs_UI_Text13"), count, max_count))
end

function M:is_tag_selected(tag_id)
  return self._selected_tags[tag_id] == true
end

function M:on_tag_toggled(tag_id, is_on)
  if is_on then
    local count = 0
    for _, _ in pairs(self._selected_tags) do
      count = count + 1
    end
    local max_count = self._max_tag_count or little_corner_module.max_choose_tag_count
    if count >= max_count then
      return false
    end
    self._selected_tags[tag_id] = true
  else
    self._selected_tags[tag_id] = nil
  end
  self:_refresh_selected_count()
  return true
end

function M:_on_btn_confirm_click()
  local tag_list = {}
  for tag_id, _ in pairs(self._selected_tags) do
    table.insert(tag_list, tag_id)
  end
  if self._custom_on_confirm then
    self._custom_on_confirm(tag_list)
  else
    little_corner_module:set_draft_tags(tag_list)
  end
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_reset_click()
  self._selected_tags = {}
  for _, group_item in ipairs(self._group_items) do
    if not_null(group_item.game_obj) and group_item.game_obj.activeSelf then
      group_item:_refresh_ui()
    end
  end
  self:_refresh_selected_count()
end

function M:_on_btn_close_click()
  UIManagerInstance:close(self.guid)
end

return M
