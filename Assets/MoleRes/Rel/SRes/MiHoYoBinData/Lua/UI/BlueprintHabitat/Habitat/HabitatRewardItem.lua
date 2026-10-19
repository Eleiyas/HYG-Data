local ItemV2Panel = require("UI/Item/ItemV2Panel")
local M = G.Class("HabitatRewardItem", ItemV2Panel)
local base = ItemV2Panel

function M:init()
  base.init(self)
  self._habitat_id = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:refresh_as_reward(habitat_id)
  self._habitat_id = habitat_id or 0
  local reward = blueprint_habitat_module:get_habitat_reward(self._habitat_id)
  local item_id = reward and reward.id or 0
  if item_id == 0 then
    return
  end
  local restored = blueprint_habitat_module:has_habitat_ever_been_restored(self._habitat_id)
  local claimed = blueprint_habitat_module:is_habitat_reward_claimed(self._habitat_id)
  self:set_item_data(item_id, reward.num or 1)
  if restored and not claimed then
    self:bind_callback(self._btn, function()
      blueprint_habitat_module:claim_habitat_restore_reward(habitat_id)
    end)
  else
    self:bind_item_info_btn(item_id)
  end
  self:_refresh_claim_state(restored, claimed)
end

function M:refresh_as_creature(habitat_id)
  self._habitat_id = habitat_id or 0
  local creature_id = blueprint_habitat_module:get_habitat_creature_id(self._habitat_id)
  self:set_item_data(creature_id, 1)
  if 0 < creature_id then
    self:bind_item_info_btn(creature_id)
  end
  self:_refresh_creature_state()
end

function M:_refresh_npc_state()
  if is_null(self._ui_state_group_habitat_npc) then
    return
  end
  local has_npc = false
  local ok, cfg = CsHabitatModuleUtil.TryGetHabitatCfg(self._habitat_id)
  if ok and cfg and cfg.RelatedNpcID ~= 0 then
    local npc_cfg = npc_module:get_npc_cfg(cfg.RelatedNpcID)
    if npc_cfg then
      has_npc = true
      UIUtil.set_image(self._icon_npc, npc_cfg.iconnamesmall, self:get_load_proxy())
    end
  end
  self._ui_state_group_habitat_npc:SetState(has_npc and 1 or 0)
end

function M:_refresh_claim_state(restored, claimed)
  if is_null(self._ui_state_group_habitat_claim) then
    return
  end
  if claimed and restored then
    self._ui_state_group_habitat_claim:SetState(2)
  elseif restored then
    self._ui_state_group_habitat_claim:SetState(1)
  else
    self._ui_state_group_habitat_claim:SetState(0)
  end
end

function M:_refresh_creature_state()
  if is_null(self._ui_state_group_habitat_creature) then
    return
  end
  local unlocked = blueprint_habitat_module:is_habitat_creature_unlocked(self._habitat_id)
  self._ui_state_group_habitat_creature:SetState(unlocked and 1 or 0)
end

return M
