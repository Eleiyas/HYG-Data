local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("PersonalRecordSection", base_path)
local base = G.DetailSectionBase
local INFO_ITEM_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/InfoItemView"

function M:on_create()
  base.on_create(self)
  self._item_panels = {}
  self._list_parent = self._trans_item_info.parent
  self._trans_item_info.gameObject:SetActive(false)
end

function M:should_show(item_data)
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local records = strategy.get_personal_record_list and strategy:get_personal_record_list(item_data)
  return records and 0 < #records
end

function M:refresh(item_data)
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local records = strategy:get_personal_record_list(item_data)
  for i, record in ipairs(records) do
    local panel = self:_get_or_create(i)
    panel:set_active(true)
    panel:refresh_info(record.title, record.value)
  end
  for i = #records + 1, #self._item_panels do
    self._item_panels[i]:set_active(false)
  end
end

function M:_get_or_create(index)
  if self._item_panels[index] then
    return self._item_panels[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item_info.gameObject, self._list_parent)
  local panel = self:add_panel(INFO_ITEM_VIEW_PATH, go.transform)
  self._item_panels[index] = panel
  return panel
end

return M
