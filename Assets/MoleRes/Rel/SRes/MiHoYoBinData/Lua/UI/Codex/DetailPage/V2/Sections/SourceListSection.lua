local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("SourceListSection", base_path)
local base = G.DetailSectionBase
local MAX_SOURCE_COUNT = 3
local SOURCE_TYPE_TRACKING = 2
local S = "UI/Codex/DetailPage/V2/Sections/"
local template_cfg = {
  jump = {
    field = "_trans_item_btn_jump",
    class_path = S .. "SourceItemJump"
  },
  target = {
    field = "_trans_item_tog_target",
    class_path = S .. "SourceItemTarget"
  },
  normal = {
    field = "_trans_item_normal",
    class_path = S .. "SourceItemNormal"
  }
}

function M:on_create()
  base.on_create(self)
  self._spawned = {}
  self._spawned_count = 0
  self._list_parent = self._trans_item_normal.parent
  self._trans_item_normal.gameObject:SetActive(false)
  self._trans_item_btn_jump.gameObject:SetActive(false)
  self._trans_item_tog_target.gameObject:SetActive(false)
end

function M:should_show(item_data)
  if not item_data.IsUnlocked and item_data.Type ~= CodexDataType.Cloth and item_data.Type ~= CodexDataType.Furniture then
    return false
  end
  local sources = flatbuffer_vector_to_table(item_data.ItemCfg, "sourceid")
  return sources and 0 < #sources
end

function M:refresh(item_data)
  local sources = flatbuffer_vector_to_table(item_data.ItemCfg, "sourceid")
  local item_id = item_data.IdCfg and item_data.IdCfg.id or 0
  local is_unavailable_seasonal = self:_is_unavailable_seasonal(item_data)
  local valid_index = 1
  for i = 1, #sources do
    if valid_index > MAX_SOURCE_COUNT then
      break
    end
    local source_id = sources[i]
    local cfg = ExcelDataUtil.get_value(typeof(BSourceCfg), source_id)
    if not_null(cfg) then
      local key = is_unavailable_seasonal and "normal" or self:_get_template_key(cfg)
      local panel = self:_get_or_create(valid_index, key)
      panel:set_active(true)
      panel:refresh(cfg, item_id, is_unavailable_seasonal)
      valid_index = valid_index + 1
    end
  end
  local spawned_count = self._spawned_count or #self._spawned
  for i = valid_index, spawned_count do
    local entry = self._spawned[i]
    if entry ~= nil then
      local panel = entry.panel
      if panel ~= nil then
        panel:set_active(false)
      end
    end
  end
end

function M:_get_template_key(cfg)
  if cfg.systemjump > 0 then
    return "jump"
  elseif cfg.sourcetype == SOURCE_TYPE_TRACKING then
    return "target"
  end
  return "normal"
end

function M:_get_or_create(index, key)
  local entry = self._spawned[index]
  if entry and entry.key == key then
    return entry.panel
  end
  if entry then
    self:remove_panel(entry.panel)
    self._spawned[index] = nil
  end
  local tc = template_cfg[key]
  local go = UIUtil.load_prefab_set_parent(self[tc.field].gameObject, self._list_parent)
  local panel = self:add_panel(tc.class_path, go.transform)
  self._spawned[index] = {panel = panel, key = key}
  self._spawned_count = math.max(self._spawned_count or 0, index)
  return panel
end

function M:_is_unavailable_seasonal(item_data)
  if not item_data then
    return false
  end
  local season_id = item_data.SeasonID
  if not season_id or season_id == 0 then
    return false
  end
  return not item_data.IsSeasonal
end

return M
