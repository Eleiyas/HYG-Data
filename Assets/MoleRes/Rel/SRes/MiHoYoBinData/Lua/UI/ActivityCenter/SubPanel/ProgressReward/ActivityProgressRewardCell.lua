local M = G.Class("ActivityProgressRewardCell", G.UIPanel)
local base = G.UIPanel
local RewardState = {
  Locked = 0,
  CanClaim = 1,
  Claimed = 2
}

function M:init()
  base.init(self)
  self._entry = nil
  self._item_panel = nil
  self._on_claim = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item_v2) then
    self._item_panel = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item_v2.transform)
    local item_btn = self._item_panel:get_btn()
    if not is_null(item_btn) then
      self:bind_callback(item_btn, function()
        if not is_null(self._btn_claim) then
          self._btn_claim.onClick:Invoke()
        end
      end)
    end
  end
  if not is_null(self._btn_claim) then
    self:bind_callback(self._btn_claim, function()
      if self._entry ~= nil and self._on_claim ~= nil then
        self._on_claim(self._entry)
      end
    end)
  end
end

function M:set_claim_callback(callback)
  self._on_claim = callback
end

function M:refresh(entry)
  self._entry = entry
  if entry == nil then
    return
  end
  UIUtil.set_text_by_id(self._text_level, "PlanetTreeActivity_TreeLevel2", tostring(entry.DisplayLevel))
  if self._item_panel ~= nil then
    if entry.PreviewItemId ~= 0 then
      self._item_panel:set_item_data(entry.PreviewItemId, entry.PreviewItemCount)
    else
      self._item_panel:set_empty()
    end
  end
  local state = RewardState.Locked
  if entry.IsTaken then
    state = RewardState.Claimed
  elseif entry.CanClaim then
    state = RewardState.CanClaim
  end
  if not_null(self._state_group) then
    self._state_group:SetState(state)
  end
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(state == RewardState.CanClaim and RedPointType.GiftRP or RedPointType.None)
  end
end

return M
