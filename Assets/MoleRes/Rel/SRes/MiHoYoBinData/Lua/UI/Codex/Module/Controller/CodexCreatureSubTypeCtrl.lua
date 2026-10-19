local Base = require("UI/Codex/Module/CodexSubTypeCtrlBase")
local M = G.Class("CodexCreatureSubTypeCtrl", Base)
local codex_module = _ENV.codex_module

function M:_is_creature_tag_reward_sub_type()
  local sub_type_cfg = self:get_sub_type_cfg()
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if not tag then
    return false
  end
  local cs_list = CsCodexModuleUtil.GetCreatureTagNumRewardListByTag(tag)
  return not_null(cs_list) and cs_list.Count > 0
end

function M:_has_creature_tag_reward()
  local sub_type_cfg = self:get_sub_type_cfg()
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if not tag then
    return false
  end
  local cs_list = CsCodexModuleUtil.GetCreatureTagNumRewardListByTag(tag)
  if is_null(cs_list) or cs_list.Count == 0 then
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

function M:_has_progress_reward()
  if self:_has_creature_tag_reward() then
    return true
  end
  local unlock_cfgs = self:get_unlock_cfgs()
  if not unlock_cfgs then
    return false
  end
  local sub_type_cfg = self:get_sub_type_cfg()
  local sub_type_id = self.sub_type or nil
  if sub_type_cfg and sub_type_cfg.subtype then
    sub_type_id = sub_type_cfg.subtype
  end
  if sub_type_id == nil then
    return false
  end
  if self:_is_creature_tag_reward_sub_type() then
    return false
  end
  for _, cfg in ipairs(unlock_cfgs) do
    local reward_data = CsCodexModuleUtil.GetSubTypeLevelRewardData(sub_type_id, cfg.level)
    if self:get_unlocked_item_count() >= cfg.num and not_null(reward_data) and not reward_data.IsRewardsTaken then
      return true
    end
  end
  return false
end

return M
