local item_v2_cls = item_module.item_v2_panel_cls_name
local ANIMATOR_TRIGGERS = {"normal", "loop"}
local M = G.Class("SpringFestivalExChangeCraftCell", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._item_id = 0
  self._on_click_cb = nil
  self._item_v2_panel = nil
  self._clickable = false
  self._obj_item_v2_basic = nil
  self._btn_craft = nil
  self._state_craft = nil
  self._animator = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._obj_item_v2_basic) then
    self._item_v2_panel = self:add_panel(item_v2_cls, self._obj_item_v2_basic)
  end
  if not_null(self._btn_craft) then
    self:bind_callback(self._btn_craft, pack(self, M._on_click_craft))
    self._animator = self._btn_craft.gameObject:GetComponent(typeof(CS.UnityEngine.Animator))
  end
end

function M:_reset_all_animator_triggers()
  if is_null(self._animator) then
    return
  end
  for _, trigger_name in ipairs(ANIMATOR_TRIGGERS) do
    self._animator:ResetTrigger(trigger_name)
  end
end

function M:set_data(item_id, on_click_cb)
  self._item_id = item_id or 0
  self._on_click_cb = on_click_cb
  if self._item_v2_panel ~= nil and self._item_id ~= 0 then
    self._item_v2_panel:set_item_data(self._item_id, nil, nil)
    self._item_v2_panel:bind_item_info_btn(self._item_id)
  end
end

function M:refresh(cur, need, can_combine, can_flash)
  if self._item_v2_panel ~= nil then
    self._item_v2_panel:set_num_required(cur, need, item_module.EMarkWarning.WhenZero)
  end
  self._clickable = can_combine == true
  local should_flash
  if can_flash == nil then
    should_flash = self._clickable
  else
    should_flash = can_flash == true
  end
  local state_idx = should_flash and cur <= 0 and 1 or 0
  if not_null(self._state_craft) then
    self:_reset_all_animator_triggers()
    self._state_craft:SetState(state_idx)
  end
end

function M:get_item_id()
  return self._item_id
end

function M:_on_click_craft()
  if not self._clickable then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("SpringFestival_HUDCommonTip_CantExchange"))
    return
  end
  if self._on_click_cb ~= nil then
    self._on_click_cb(self._item_id)
  end
end

return M
