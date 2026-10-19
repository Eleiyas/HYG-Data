local M = G.Class("SpringFestivalLanternMissionPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._item_panel = nil
  self._stage = 0
  self._state = 0
  self._on_claim_callback = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item) then
    self._item_panel = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item)
  end
  if not is_null(self._toggle) then
    self:bind_callback(self._toggle, pack(self, M._on_click_claim))
  end
end

function M:refresh(data, on_claim_callback)
  if data == nil then
    return
  end
  self._stage = data.stage or 0
  self._state = riddle_module:get_stage_reward_state(data)
  self._on_claim_callback = on_claim_callback
  if not is_null(self._state_reward) then
    self._state_reward:SetState(self._state)
  end
  if not is_null(self._trans_block) then
    UIUtil.set_active(self._trans_block, self._state == riddle_module.stage_reward_state.taken)
  end
  if not is_null(self._red_point) then
    if self._state == riddle_module.stage_reward_state.can_take then
      self._red_point:ShowRedPoint(RedPointType.GiftRP)
    else
      self._red_point:ShowRedPoint(RedPointType.None)
    end
  end
  if not is_null(self._text_num) then
    UIUtil.set_text(self._text_num, tostring(data.need_active or 0))
  end
  if self._item_panel == nil then
    return
  end
  local item_id, item_num = riddle_module:get_stage_reward_display_item(data)
  if item_id <= 0 then
    self._item_panel:set_active(false)
    return
  end
  self._item_panel:set_active(true)
  self._item_panel:set_item_data(item_id, item_num)
  self._item_panel:bind_item_info_btn(item_id)
end

function M:_on_click_claim()
  if self._state ~= riddle_module.stage_reward_state.can_take then
    return
  end
  if self._on_claim_callback == nil then
    return
  end
  self._on_claim_callback(self._stage)
end

return M
