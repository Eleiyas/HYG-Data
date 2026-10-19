local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("PackageRewardSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self._item_cls = nil
  self._item_data = nil
  self._reward_cfg_id = 0
  local content_trans = UIUtil.find_trans(self._trans_item_middle_lite, "content")
  self._item_cls = item_module:init_item_cls(content_trans)
  if not_null(self._item_cls.btn) then
    self:bind_callback(self._item_cls.btn, pack(self, M._on_btn_click))
  end
end

function M:should_show(item_data)
  return codex_module:is_package_sub_type(item_data.SubType)
end

function M:_get_suite_reward_state(item_data)
  local suite = item_data.ServerData and item_data.ServerData.Suite
  if not suite then
    return 0
  end
  if 0 < suite.CompleteTime and suite.IsCompleteRewardTaken then
    return 2
  elseif 0 < suite.CompleteTime then
    return 1
  end
  return 0
end

function M:refresh(item_data)
  self._item_data = item_data
  self._reward_state = self:_get_suite_reward_state(item_data)
  self._ui_state_group_item:SetState(self._reward_state)
  self:_refresh_red_point()
  local reward_pool_id = item_data.CodexCfg.suiterewardpoolid
  local pool_cfgs = ExcelDataUtil.get_value(typeof(BRandomPoolCfg), reward_pool_id)
  if not pool_cfgs then
    return
  end
  pool_cfgs = list_to_table(pool_cfgs)
  if 0 < #pool_cfgs then
    local cfg = pool_cfgs[1]
    self._reward_cfg_id = cfg.configid
    self._reward_num = cfg.num
    item_module:set_item_cls(self._item_cls, cfg.configid, cfg.num, self:get_load_proxy())
    UIUtil.set_active(self._trans_item_middle_lite, true)
  else
    self._reward_cfg_id = 0
    UIUtil.set_active(self._trans_item_middle_lite, false)
  end
end

function M:_refresh_red_point()
  if self._red_point == nil or is_null(self._red_point) then
    return
  end
  if self._reward_state == 1 then
    self._red_point:ShowRedPoint(RedPointType.GiftRP)
  else
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_on_btn_click()
  if self._reward_state == 1 then
    self:_take_reward()
  else
    self:_show_item_info()
  end
end

function M:_show_item_info()
  if self._reward_cfg_id == 0 then
    return
  end
  item_module:open_item_info_dialog(self._reward_cfg_id, self._reward_num or 0)
end

function M:_show_suite_rewards(rewards)
  if is_null(rewards) or is_null(rewards.RewardItemList) then
    return
  end
  local reward_list = array_to_table(rewards.RewardItemList)
  local merged_map = {}
  local merged_order = {}
  for _, v in ipairs(reward_list) do
    local id = v.ItemConfigId
    if merged_map[id] then
      merged_map[id] = merged_map[id] + v.Count
    else
      merged_map[id] = v.Count
      table.insert(merged_order, id)
    end
  end
  local items = {}
  for _, id in ipairs(merged_order) do
    table.insert(items, {
      id = id,
      num = merged_map[id]
    })
  end
  if 0 < #items then
    common_ui_module:show_reward_dialog(nil, nil, items)
  end
end

function M:_take_reward()
  if not self._item_data or not self._item_data.IdCfg then
    return
  end
  CsCodexModuleUtil.TakePackageCompleteReward(self._item_data.IdCfg.id, function(rsp)
    if is_null(self) then
      return
    end
    if rsp.Retcode == 0 then
      self._reward_state = 2
      self._ui_state_group_item:SetState(2)
      self:_refresh_red_point()
      self:_show_suite_rewards(rsp.Rewards)
      lua_event_module:send_event(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, nil)
    else
      UIUtil.show_tips_by_text_id("Codex_Tips_TakeRewardFail")
    end
  end)
end

return M
