local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("PackageListSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self._items = {}
  self._trans_item.gameObject:SetActive(false)
end

local PACKAGE_TITLE_ICON = {
  [CodexDataType.Furniture] = "UISprite/Load/TabIcon/Icon_Common_Tab_Furniture",
  [CodexDataType.Cloth] = "UISprite/Load/TabIcon/Icon_Common_Tab_Clothe"
}

function M:should_show(item_data)
  return codex_module:is_package_sub_type(item_data.SubType)
end

function M:refresh(item_data)
  self._holder_item_data = item_data
  local ids = item_data.PackageItemIds
  local total = ids.Count
  local unlocked_count = 0
  local sorted_ids = self:_get_sorted_ids(ids, item_data.Type)
  for i, cid in ipairs(sorted_ids) do
    local cd = codex_module:get_data_by_id(cid)
    local is_unlocked = cd and cd.IsUnlocked
    if is_unlocked then
      unlocked_count = unlocked_count + 1
    end
    local entry = self:_get_or_create(i)
    entry.item_panel:set_item_data(cid, 0)
    if entry.lock_group then
      entry.lock_group:SetState(is_unlocked and 1 or 0)
    end
    entry.config_id = cid
    entry.go:SetActive(true)
  end
  for i = total + 1, #self._items do
    self._items[i].go:SetActive(false)
  end
  UIUtil.set_text(self._txt_title_package, string.format("%s（%d/%d）", UIUtil.get_text_by_id("Codex_PackageComponent"), unlocked_count, total))
  if not_null(self._img_title_icon) then
    local icon_path = PACKAGE_TITLE_ICON[item_data.Type]
    if icon_path then
      UIUtil.set_image(self._img_title_icon, icon_path, self:get_load_proxy())
    end
  end
end

function M:_get_or_create(index)
  if self._items[index] then
    return self._items[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item.gameObject, self._trans_item_group_list)
  local item_panel = self:add_panel(item_module.item_v2_panel_cls_name, go.transform)
  local node_trans = UIUtil.find_trans(go.transform, "scale/node")
  local entry = {
    go = go,
    item_panel = item_panel,
    lock_group = node_trans and UIUtil.find_ui_state_group(node_trans, "ui_state_group_lock") or nil,
    config_id = 0
  }
  local btn = item_panel:get_btn()
  if not_null(btn) then
    self:bind_callback(btn, function()
      self:_on_item_click(entry)
    end)
  end
  self._items[index] = entry
  return entry
end

function M:_on_item_click(entry)
  if not entry or entry.config_id == 0 then
    return
  end
  local cid = entry.config_id
  local data = codex_module:get_data_by_id(cid)
  if not_null(data) and not data.IsUnlocked then
    self:_show_confirm_jump(cid, data)
  else
    UIManagerInstance:open("UI/Codex/CodexItemInfoDialog", {cfg_id = cid, num = 0})
  end
end

function M:_need_show_name_in_confirm(codex_data)
  if is_null(codex_data) then
    return false
  end
  if codex_data.IsUnlocked then
    return true
  end
  if codex_module:is_furniture_type(codex_data.Type) or codex_data.Type == CodexDataType.Cloth then
    return true
  end
  return false
end

function M:_show_confirm_jump(cid, codex_data)
  local popup = UIUtil.get_confirm_popup()
  local text = UIUtil.get_text_by_id("Codex_Tips_Unlock_Jump")
  local name_text = codex_module.default_lock_info
  if self:_need_show_name_in_confirm(codex_data) then
    name_text = codex_data.IdCfg.name
  end
  text = string.format(text, name_text)
  popup:set_texts(text, UIUtil.get_text_by_id("Codex_Confirm"), UIUtil.get_text_by_id("Codex_Cancel"), nil)
  popup:set_callbacks(function()
    local strategy = codex_module:get_type_view_strategy(self._holder_item_data.Type)
    local class_path = strategy:get_detail_page_class()
    local window = UIManagerInstance:get_window_by_class(class_path)
    local d = {
      item_id = cid,
      enter_type = codex_module.codex_page_enter_type.item_detail_dialog
    }
    if window then
      window:set_extra_data(d)
      window:refresh()
    else
      UIManagerInstance:open(class_path, d)
    end
  end)
  popup:show()
end

function M:_get_sorted_ids(ids, data_type)
  local list = {}
  for i = 0, ids.Count - 1 do
    table.insert(list, ids[i])
  end
  if data_type == CodexDataType.Cloth or data_type == CodexDataType.Furniture then
    local unlocked = {}
    local locked = {}
    for _, cid in ipairs(list) do
      local cd = codex_module:get_data_by_id(cid)
      if cd and cd.IsUnlocked then
        table.insert(unlocked, cid)
      else
        table.insert(locked, cid)
      end
    end
    list = unlocked
    for _, cid in ipairs(locked) do
      table.insert(list, cid)
    end
  end
  return list
end

return M
