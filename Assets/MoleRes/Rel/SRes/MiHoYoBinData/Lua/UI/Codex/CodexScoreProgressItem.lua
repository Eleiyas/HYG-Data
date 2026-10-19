local M = G.Class("CodexScoreProgressItem", G.UIPanel)
local base = G.UIPanel
M.State = {
  UNCOMPLETED = 0,
  TO_CLAIM = 1,
  CLAIMED = 2
}
M.StateGroupIndex = {
  [M.State.CLAIMED] = 0,
  [M.State.TO_CLAIM] = 1,
  [M.State.UNCOMPLETED] = 2
}

function M:init()
  base.init(self)
  self._cfg = nil
  self._index = 0
  self._state = M.State.UNCOMPLETED
  self._claim_callback = nil
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  if not_null(self._trans_item) then
    self._trans_item.gameObject:SetActive(false)
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_reward) then
    self:bind_callback(self._btn_reward, pack(self, M._on_btn_reward))
  end
end

function M:set_data(cfg, index)
  self._cfg = cfg
  self._index = index or 0
end

function M:refresh(total_score_data, rewarded_id_table, load_proxy)
  self:refresh_by_score(total_score_data.TotalScore, total_score_data, rewarded_id_table, load_proxy)
end

function M:refresh_by_score(score, _total_score_data, rewarded_id_table, load_proxy, show_reward)
  if self._cfg == nil then
    return
  end
  if not_null(self._ui_state_group_type) then
    self._ui_state_group_type:SetState(self:get_score() == 0 and 1 or 0)
  end
  local need_score = self._cfg.needtotalscore
  if score >= need_score and rewarded_id_table[self._cfg.id] then
    self._state = M.State.CLAIMED
  elseif score >= need_score then
    self._state = M.State.TO_CLAIM
  else
    self._state = M.State.UNCOMPLETED
  end
  self:_apply_state_visual()
  if not_null(self._txt_score) then
    UIUtil.set_text(self._txt_score, tostring(need_score))
  end
  if not_null(self._txt_dot_score) then
    UIUtil.set_text(self._txt_dot_score, tostring(need_score))
  end
  if not_null(self._txt_describe) and self._cfg.name ~= nil then
    UIUtil.set_text(self._txt_describe, self._cfg.name)
  end
  if show_reward then
    self:_refresh_reward_items()
  end
end

function M:_apply_state_visual()
  if not_null(self._ui_state_group_claim) then
    self._ui_state_group_claim:SetState(M.StateGroupIndex[self._state] or 0)
  end
end

function M:_collect_valid_reward_cfgs()
  if self._cfg == nil then
    return {}
  end
  local rand_pool_cfgs = ExcelDataUtil.get_value(typeof(BRandomPoolCfg), self._cfg.rewardrandompoolid)
  if is_null(rand_pool_cfgs) then
    return {}
  end
  local cfgs = list_to_table(rand_pool_cfgs)
  local valid_cfgs = {}
  for i = 1, #cfgs do
    local configid = cfgs[i].configid
    local item_cfg = configid ~= nil and 0 < configid and item_module:get_cfg_by_id(configid) or nil
    if item_cfg ~= nil and item_cfg.icon ~= nil and item_cfg.icon ~= "" then
      table.insert(valid_cfgs, cfgs[i])
    end
  end
  return self:_sort_by_title_first(valid_cfgs)
end

function M:_sort_by_title_first(cfgs)
  local is_title = {}
  for i = 1, #cfgs do
    is_title[i] = item_module:is_player_title(cfgs[i].configid)
  end
  local indices = {}
  for i = 1, #cfgs do
    indices[i] = i
  end
  table.sort(indices, function(a, b)
    if is_title[a] ~= is_title[b] then
      return is_title[a]
    end
    return a < b
  end)
  local sorted = {}
  for i = 1, #indices do
    sorted[i] = cfgs[indices[i]]
  end
  return sorted
end

function M:_get_title_owned_num(item_id)
  local title_id = 0
  local title_cfgs = ExcelDataUtil.get_table(typeof(BPlayerTitleCfg)) or {}
  for _, title_cfg in pairs(title_cfgs) do
    if not is_null(title_cfg) and title_cfg.itemid == item_id then
      title_id = title_cfg.titleid
      break
    end
  end
  if title_id <= 0 then
    return 0
  end
  local unlock_title_data_list = CsSocialModuleUtil.UnlockTitleDataList
  if is_null(unlock_title_data_list) then
    return 0
  end
  local unlocked_title_data_list = list_to_table(unlock_title_data_list) or {}
  for _, title_data in ipairs(unlocked_title_data_list) do
    if not is_null(title_data) and title_data.TitleId == title_id then
      return 1
    end
  end
  return 0
end

function M:_open_title_info_dialog(item_id)
  item_module:open_item_info_dialog_by_data({
    cfg_id = item_id,
    owned_num = self:_get_title_owned_num(item_id)
  })
end

function M:get_reward_items()
  local valid_cfgs = self:_collect_valid_reward_cfgs()
  local items = {}
  for i = 1, #valid_cfgs do
    table.insert(items, {
      id = valid_cfgs[i].configid,
      num = valid_cfgs[i].num
    })
  end
  return items
end

function M:_refresh_reward_items()
  if self._cfg == nil or is_null(self._trans_reward_content) then
    return
  end
  local valid_cfgs = self:_collect_valid_reward_cfgs()
  for i = 1, #valid_cfgs do
    local reward_cfg = valid_cfgs[i]
    if reward_cfg == nil then
      break
    end
    local entry = self:_get_or_create_reward_item(i)
    if entry == nil then
      break
    end
    local reward_cfg_id = reward_cfg.configid
    entry.reward_cfg_id = reward_cfg_id
    entry.item_panel:set_item_data(reward_cfg_id, reward_cfg.num)
    entry.go:SetActive(true)
  end
  for i = #valid_cfgs + 1, #self._reward_items do
    self._reward_items[i].go:SetActive(false)
  end
end

function M:_get_or_create_reward_item(index)
  if self._reward_items[index] then
    return self._reward_items[index]
  end
  if is_null(self._trans_item) then
    return nil
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item.gameObject, self._trans_reward_content)
  if is_null(go) then
    return nil
  end
  local item_panel = self:add_panel(item_module.item_v2_panel_cls_name, go.transform)
  local entry = {
    go = go,
    item_panel = item_panel,
    reward_cfg_id = 0
  }
  local btn = item_panel:get_btn()
  if not_null(btn) then
    item_panel:bind_callback(btn, function()
      local reward_cfg_id = entry.reward_cfg_id or 0
      if reward_cfg_id <= 0 then
        return
      end
      if item_module:is_player_title(reward_cfg_id) then
        self:_open_title_info_dialog(reward_cfg_id)
      else
        item_module:open_item_info_dialog_by_data({cfg_id = reward_cfg_id})
      end
    end)
  end
  self._reward_items[index] = entry
  return entry
end

function M:set_claim_callback(callback)
  self._claim_callback = callback
end

function M:_on_btn_reward()
  if self._claim_callback then
    self._claim_callback()
  end
end

function M:get_state()
  return self._state
end

function M:get_score()
  return self._cfg and self._cfg.needtotalscore or 0
end

function M:get_cfg()
  return self._cfg
end

function M:get_index()
  return self._index
end

function M:show_panel(show)
  local should_show = show and self:get_score() > 0
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if not_null(self._ui_state_group_panel) then
      self._ui_state_group_panel:SetState(should_show and 1 or 0)
    end
  end)
end

function M:set_state_visual(state)
  self._state = state
  self:_apply_state_visual()
end

function M:clear_cache()
  for _, entry in ipairs(self._reward_items) do
    if not_null(entry.go) then
      UIUtil.destroy_go(entry.go)
    end
  end
  self._reward_items = {}
end

return M
