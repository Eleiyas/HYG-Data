local M = G.Class("StarExpressAwardLevelItem", G.UIPanel)
local base = G.UIPanel
local pos_state = {
  first = 0,
  middle = 1,
  last = 2
}
local unlock_state = {
  locked = 0,
  current = 1,
  unlocked = 2
}
local award_state = {
  unclaimable = 0,
  claimable = 1,
  claimed = 2
}

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self._describe_objs = {}
  if self._btn ~= nil then
    self:bind_callback(self._btn, pack(self, M._on_btn_click))
  end
  if self._obj_item ~= nil then
    self._reward_item = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item)
  end
end

function M:refresh(cfg, cur_level, index, total)
  if cfg == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._cfg = cfg
  self._cur_level = cur_level or 0
  if self._txt_lv ~= nil then
    UIUtil.set_text(self._txt_lv, TextMapFormatUtil.FormatInteger(cfg.level or 0))
  end
  if self._txt_title ~= nil then
    UIUtil.set_text_by_id(self._txt_title, cfg.titlename or "")
  end
  self:_refresh_describes(cfg)
  self:_refresh_reward(cfg)
  self:_refresh_pos_state(index, total)
  self:_refresh_level_state()
end

function M:_refresh_describes(cfg)
  if self._obj_describe == nil then
    return
  end
  local text_ids = {}
  for _, raw_id in ipairs(lua_str_split(cfg.upgradedesc, ",")) do
    local text_id = string.gsub(raw_id, "^%s*(.-)%s*$", "%1")
    if string.is_valid(text_id) then
      table.insert(text_ids, text_id)
    end
  end
  for index, text_id in ipairs(text_ids) do
    local go = self:_get_describe_obj(index)
    UIUtil.set_active(go, true)
    if text_id == "StarExpress_RiderLevel_GainNameTag" then
      UIUtil.set_text_by_id(go, text_id, self:_get_reward_title_name(cfg))
    else
      UIUtil.set_text_by_id(go, text_id)
    end
  end
  self:_get_describe_obj(1)
  for i = #text_ids + 1, #self._describe_objs do
    UIUtil.set_active(self._describe_objs[i], false)
  end
end

function M:_get_reward_title_name(cfg)
  local item_id = 0 < (cfg.rewarditemsLength or 0) and tonumber(cfg:rewarditems(0)) or 0
  if item_id == nil or item_id <= 0 then
    return ""
  end
  local title_cfgs = ExcelDataUtil.get_table(typeof(BPlayerTitleCfg))
  for _, title_cfg in pairs(title_cfgs) do
    if not is_null(title_cfg) and title_cfg.itemid == item_id then
      return title_cfg.playertitlename or ""
    end
  end
  return ""
end

function M:_get_describe_obj(index)
  if self._describe_objs[index] ~= nil then
    return self._describe_objs[index]
  end
  local go = index == 1 and self._obj_describe or UIUtil.load_prefab_set_parent(self._obj_describe, self._obj_describe.transform.parent)
  self._describe_objs[index] = go
  return go
end

function M:_refresh_reward(cfg)
  if self._reward_item == nil then
    return
  end
  local item_id = star_express_module:get_rider_reward_item_id(cfg)
  self._reward_item:set_active(0 < item_id)
  if item_id <= 0 then
    return
  end
  local item_num = 0 < (cfg.rewarditemcountLength or 0) and cfg:rewarditemcount(0) or nil
  self._reward_item:set_item_data(item_id, item_num)
  self._reward_item:bind_item_info_btn(item_id)
end

function M:_refresh_pos_state(index, total)
  if self._state_group_pos == nil then
    return
  end
  if index == 1 then
    self._state_group_pos:SetState(pos_state.first)
  elseif index == total then
    self._state_group_pos:SetState(pos_state.last)
  else
    self._state_group_pos:SetState(pos_state.middle)
  end
end

function M:_refresh_level_state()
  if self._cfg == nil then
    return
  end
  local level = self._cfg.level or 0
  local unlock
  if level < self._cur_level then
    unlock = unlock_state.unlocked
  elseif level == self._cur_level then
    unlock = unlock_state.current
  else
    unlock = unlock_state.locked
  end
  if self._state_group_unlock ~= nil then
    self._state_group_unlock:SetState(unlock)
  end
  local award
  if unlock == unlock_state.locked then
    award = award_state.unclaimable
  elseif star_express_module:can_claim_rider_reward(level) then
    award = award_state.claimable
  else
    award = award_state.claimed
  end
  self._can_claim = award == award_state.claimable
  if self._state_group_award ~= nil then
    self._state_group_award:SetState(award)
  end
end

function M:play_item_enter_anim()
  if self._has_binder then
    self.binder:PlayEnterAnim(nil)
  end
end

function M:play_item_exit_anim()
  if self._has_binder then
    self.binder:PlayExitAnim(nil)
  end
end

function M:_on_btn_click()
  if not self._can_claim or self._claiming then
    return
  end
  self._claiming = true
  star_express_module:claim_rider_reward(self._cfg.level, function(success)
    self._claiming = false
    if not success or not self.is_active then
      return
    end
    self:_refresh_level_state()
  end)
end

return M
