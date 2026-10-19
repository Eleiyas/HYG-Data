local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("PlantProductSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self._items = {}
  if not_null(self._trans_item) then
    self._trans_item.gameObject:SetActive(false)
  end
end

function M:should_show(item_data)
  if not (item_data and item_data.IsUnlocked) or item_data.SubType ~= CodexDataSubType.PlantGreen then
    return false
  end
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  if not strategy or not strategy._get_fruit_item_id then
    return false
  end
  local fruit_id = strategy:_get_fruit_item_id(item_data)
  return 0 < fruit_id
end

function M:refresh(item_data)
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local show_info = strategy:_is_info_visible(item_data)
  if not_null(self._txt_title_product) then
    UIUtil.set_text_by_id(self._txt_title_product, "Codex_PlantProduct")
  end
  local fruit_id = strategy:_get_fruit_item_id(item_data)
  local entry = self:_get_or_create(1)
  entry.item_panel:set_item_data(fruit_id, 0)
  if entry.lock_group then
    entry.lock_group:SetState(show_info and 1 or 0)
  end
  entry.go:SetActive(true)
  for i = 2, #self._items do
    self._items[i].go:SetActive(false)
  end
  if not_null(self._txt_product_num) then
    if show_info then
      local sd = item_data.MatureTreeDetail
      local fruit = not_null(sd) and sd.FruitDetail or nil
      local count = not_null(fruit) and (fruit.HarvestedCount or 0) or 0
      local text = string.format("%s: %d", UIUtil.get_text_by_id("Codex_HarvestCount"), count)
      UIUtil.set_text(self._txt_product_num, text)
    else
      UIUtil.set_text(self._txt_product_num, codex_module.default_lock_info)
    end
  end
  self:bind_callback(entry.btn, function()
    item_module:open_item_info_dialog(fruit_id)
  end)
end

function M:_get_or_create(index)
  if self._items[index] then
    return self._items[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item.gameObject, self._trans_item_group_list)
  local item_panel = self:add_panel(item_module.item_v2_panel_cls_name, go.transform)
  local node_trans = UIUtil.find_trans(go.transform, "scale/node")
  local btn = item_panel:get_btn()
  local entry = {
    go = go,
    item_panel = item_panel,
    lock_group = node_trans and UIUtil.find_ui_state_group(node_trans, "ui_state_group_lock") or nil,
    btn = btn
  }
  self._items[index] = entry
  return entry
end

return M
