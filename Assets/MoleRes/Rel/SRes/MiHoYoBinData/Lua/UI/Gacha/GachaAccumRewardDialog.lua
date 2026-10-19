local M = G.Class("GachaAccumRewardDialog", G.UIWindow)
local base = G.UIWindow
local accum_item_cls = GachaConst.item_path.accum_reward

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.accum_reward
  self.config.type = EUIType.Dialog
  self._gacha_id = 0
  self._gacha_pool_id = 0
  self._reward_list = {}
  self._total_draw = 0
  self._claimed_set = {}
  self._item_map = {}
  self._scroller_inited = false
  self._on_claim = pack(self, M._on_item_claim)
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.GachaAccumRewardClaimResult, pack(self, M._on_claim_result))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_info()
  self:_refresh_view(true)
end

function M:on_destroy()
  self._item_map = {}
  base.on_destroy(self)
end

function M:_refresh_info()
  local extra = self:get_extra_data()
  self._gacha_id = extra ~= nil and extra.gacha_id or gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(self._gacha_id)
  self._gacha_pool_id = activity_cfg and activity_cfg.gachapoolid or 0
  self._reward_list = gacha_module:get_accum_reward_list(self._gacha_pool_id)
end

function M:_refresh_view(is_refresh_scroll)
  self._total_draw = gacha_module:get_total_draw_count(self._gacha_id) or 0
  self._claimed_set = gacha_module:get_claimed_accum_reward_set(self._gacha_id)
  self:_refresh_progress()
  self:_refresh_list(is_refresh_scroll)
end

function M:_refresh_progress()
  if is_null(self._txt_next_reward) then
    return
  end
  local count = #self._reward_list
  local max_draw = 0 < count and self._reward_list[count].times or 0
  local slider_value, next_target_draw = self:_calc_progress()
  if count <= 0 or max_draw <= self._total_draw then
    UIUtil.set_text_by_id(self._txt_next_reward, "Gacha_Accurate_Desc_2", tostring(self._total_draw))
  else
    UIUtil.set_text_by_id(self._txt_next_reward, "Gacha_Accurate_Desc_1", tostring(self._total_draw), tostring(next_target_draw))
  end
  self._slider.value = slider_value
  UIUtil.set_text(self._txt_slider_num, tostring(self._total_draw))
  UIUtil.set_active(self._slider_tip_go, 1.0E-5 < slider_value and slider_value < 0.99999)
end

function M:_calc_progress()
  local count = #self._reward_list
  if count <= 0 then
    return 0, 0
  end
  local last_times = self._reward_list[count].times
  if last_times <= self._total_draw then
    return 1, last_times
  end
  local seg = 1 / count
  local prev_times = 0
  local prev_pos = 0
  for i = 1, count do
    local cur_times = self._reward_list[i].times
    local cur_pos = (i - 0.5) * seg
    if cur_times <= self._total_draw then
      prev_times = cur_times
      prev_pos = cur_pos
    else
      local range = cur_times - prev_times
      local drawn = self._total_draw - prev_times
      local t = 0 < range and drawn / range or 1
      if t < 0 then
        t = 0
      end
      return prev_pos + (cur_pos - prev_pos) * t, cur_times
    end
  end
  return 1, last_times
end

function M:_refresh_list(is_refresh_scroll)
  if is_null(self._scroller) then
    return
  end
  local count = #self._reward_list
  if self._scroller_inited then
    self._scroller:ReLoad(pack(self, M._refresh_item), count)
  else
    self._scroller_inited = true
    self._scroller:Init(pack(self, M._refresh_item), count)
  end
  if is_refresh_scroll then
    local first_can_claim_reward_index = self:_calc_first_can_claim_reward_index()
    self._scroller:MoveTo(0 < first_can_claim_reward_index and first_can_claim_reward_index - 1 or 0)
  end
end

function M:_calc_first_can_claim_reward_index()
  local reward_count = #self._reward_list
  if reward_count <= 0 then
    return 0
  end
  local last_reward_cfg = self._reward_list[reward_count]
  if self._total_draw >= last_reward_cfg.times and self._claimed_set[last_reward_cfg.index] then
    return reward_count
  end
  for i = 1, reward_count do
    local cfg = self._reward_list[i]
    if self._total_draw >= cfg.times and not self._claimed_set[cfg.index] then
      return i
    end
  end
  return 0
end

function M:_refresh_item(trans, index)
  local id = trans:GetInstanceID()
  local item_cls = self._item_map[id]
  if item_cls == nil then
    item_cls = self:add_panel(accum_item_cls, trans)
    item_cls:set_claim_callback(self._on_claim)
    self._item_map[id] = item_cls
  end
  local cfg = self._reward_list[index + 1]
  item_cls:refresh(cfg, self._total_draw, self._claimed_set)
  item_cls:set_active(true)
end

function M:_on_item_claim(cfg)
  if cfg == nil then
    return
  end
  gacha_module:request_gacha_accum_reward_claim(self._gacha_pool_id, cfg.index)
end

function M:_on_claim_result(rsp)
  if rsp == nil or rsp.GachaPoolId ~= self._gacha_pool_id then
    return
  end
  local items = {}
  local reward_list = list_to_table(rsp.RewardList) or {}
  for i = 1, #reward_list do
    items[#items + 1] = {
      id = reward_list[i].ConfigId,
      num = reward_list[i].Count
    }
  end
  if 0 < #items then
    common_ui_module:show_reward_dialog(nil, nil, items)
  end
  self:_refresh_view(false)
end

return M
