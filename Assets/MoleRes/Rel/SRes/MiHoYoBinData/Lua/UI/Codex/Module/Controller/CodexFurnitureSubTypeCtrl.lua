local base_class = require("UI/Codex/Module/CodexSubTypeCtrlBase")
local M = G.Class("CodexFurnitureSubTypeCtrl", base_class)

function M:is_topic_unlocked()
  return false
end

function M:has_new_items()
  if codex_module:is_package_sub_type(self.sub_type) then
    return false
  end
  return base_class.has_new_items(self)
end

function M:has_reward_items()
  if codex_module:is_package_sub_type(self.sub_type) and self:_has_package_reward() then
    return true
  end
  return false
end

function M:_has_tag_num_reward()
  local sub_type_cfg = self:get_sub_type_cfg()
  if not sub_type_cfg then
    return false
  end
  local maintype = sub_type_cfg.maintype
  if not maintype then
    return false
  end
  local tag = codex_module:get_main_tag(maintype)
  if not tag or tag == "" then
    return false
  end
  local cs_list = CsCodexModuleUtil.GetTagNumRewardListByTag(tag)
  if is_null(cs_list) then
    return false
  end
  for i = 0, cs_list.Count - 1 do
    local rd = cs_list[i]
    if rd.IsUnlocked and not rd.IsRewardTaken then
      return true
    end
  end
  return false
end

function M:_get_reindex_comparator()
  local data_tbl = self._item_id_to_data_tbl
  local cache = {}
  
  local function get_priority(id)
    if cache[id] ~= nil then
      return cache[id]
    end
    local cfg = ExcelDataUtil.get_value(typeof(BCodexCfg), id)
    local p = not is_null(cfg) and cfg.displaypriority or math.huge
    cache[id] = p
    return p
  end
  
  return function(a, b)
    local pa = get_priority(a)
    local pb = get_priority(b)
    if pa ~= pb then
      return pa > pb
    end
    return a < b
  end
end

function M:_init_group_counts()
  if self._item_count <= 0 then
    self._group_counts = {}
    return true
  end
  self._group_counts = {
    [1] = self._item_count
  }
  return true
end

return M
