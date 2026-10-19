local M = G.Class("GachaAccumRewardItem", G.UIPanel)
local base = G.UIPanel
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self._cfg = nil
  self._item_panel = nil
  self._on_claim = nil
  self._state = GachaConst.accum_reward_state.locked
  self._reward_id = 0
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item) then
    self._item_panel = self:add_panel(item_v2_cls, self._obj_item.transform)
  end
  if not_null(self._btn_claim) then
    self:bind_callback(self._btn_claim, pack(self, M._on_claim_click))
  end
end

function M:set_claim_callback(callback)
  self._on_claim = callback
end

function M:refresh(cfg, total_draw, claimed_set)
  self._cfg = cfg
  if cfg == nil then
    return
  end
  UIUtil.set_text(self._txt_socre, tostring(cfg.times))
  UIUtil.set_text(self._txt_socre_uncompleted, tostring(cfg.times))
  local state = GachaConst.accum_reward_state.locked
  if claimed_set ~= nil and claimed_set[cfg.index] then
    state = GachaConst.accum_reward_state.claimed
  elseif total_draw >= cfg.times then
    state = GachaConst.accum_reward_state.can_claim
  end
  self._state = state
  if not_null(self._ui_state_group_claim) then
    self._ui_state_group_claim:SetState(state)
  end
  if self._item_panel ~= nil then
    local reward_items = gacha_module:get_random_pool_items(cfg.randompoolid)
    local reward = reward_items[1]
    if reward ~= nil and reward.id ~= nil and reward.id ~= 0 then
      self._reward_id = reward.id
      self._item_panel:set_item_data(reward.id, reward.num)
    else
      self._reward_id = 0
      self._item_panel:set_empty()
    end
    self._item_panel:set_red_point(state == GachaConst.accum_reward_state.can_claim, RedPointType.GiftRP)
  end
end

function M:_on_claim_click()
  if self._cfg == nil or self._on_claim == nil then
    return
  end
  if self._state ~= GachaConst.accum_reward_state.can_claim then
    if (self._reward_id or 0) ~= 0 then
      item_module:open_item_info_dialog(self._reward_id)
    end
    return
  end
  self._on_claim(self._cfg)
end

return M
