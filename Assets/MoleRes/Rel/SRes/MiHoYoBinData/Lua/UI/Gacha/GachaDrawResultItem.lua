local M = G.Class("GachaDrawResultItem", G.UIBase)
local base = G.UIBase
local anim_trigger_in = "in"
local anim_trigger_repeat = "repeat"

function M:init()
  base.init(self)
  self._item_id = 0
  self._is_duplicate = false
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_info) then
    self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  end
end

function M:refresh(info, gacha_id)
  if info == nil then
    return
  end
  self._item_id = info.ItemId or 0
  if not_null(self._img_icon_dynamic) and self._item_id > 0 then
    item_module:set_item_big_icon_with_prismatic(self._img_icon_dynamic, self._item_id, nil, self:get_load_proxy(), self._img_icon_dynamic_prismatic)
    if not_null(self._img_icon_dynamic_mask) then
      item_module:set_item_big_icon(self._img_icon_dynamic_mask, self._item_id, nil, self:get_load_proxy())
    end
  else
    if not_null(self._img_icon_dynamic) then
      self._img_icon_dynamic.sprite = nil
    end
    if not_null(self._img_icon_dynamic_prismatic) then
      self._img_icon_dynamic_prismatic.sprite = nil
    end
    if not_null(self._img_icon_dynamic_mask) then
      self._img_icon_dynamic_mask.sprite = nil
    end
  end
  local item_num_str = ""
  if info.Count and info.Count > 1 then
    item_num_str = tostring(info.Count)
  end
  if not_null(self._txt_item_num) then
    UIUtil.set_text(self._txt_item_num, item_num_str)
  end
  UIUtil.set_active(self._num_node, item_num_str ~= "")
  local is_duplicate = info.IsDuplicate == true
  self._is_duplicate = is_duplicate
  UIUtil.set_active(self._btn_reconvert, is_duplicate)
  if is_duplicate then
    if not_null(self._img_coin_icon) and 0 < (info.CoinType or 0) then
      item_module:set_item_icon(self._img_coin_icon, info.CoinType, nil, nil, self:get_load_proxy())
    end
    if not_null(self._txt_coin_num) then
      UIUtil.set_text(self._txt_coin_num, tostring(info.CoinGained or 0))
    end
  end
  self._red_point:ShowRedPoint(is_duplicate and RedPointType.None or RedPointType.NewRp)
  local rank = item_module:get_item_quality_by_id(self._item_id) or 0
  self._state_group_quality:SetState(rank)
  UIUtil.set_active(self._obj_coin_item_gacha, is_duplicate)
end

function M:play_in_anim(on_complete)
  return self:_play_card_anim(anim_trigger_in, on_complete)
end

function M:play_repeat_anim()
  if not self._is_duplicate then
    return false
  end
  return self:_play_card_anim(anim_trigger_repeat, nil)
end

function M:_play_card_anim(trigger, on_complete)
  if is_null(self._anim_card_helper) then
    return false
  end
  self._anim_card_helper:SetTriggerWithCallback(trigger, on_complete, false)
  if on_complete == nil then
    self._anim_card_helper:ClearCallback()
  end
  return true
end

function M:_on_btn_info_click()
  if self._item_id > 0 then
    item_module:open_item_info_dialog(self._item_id, 1)
  end
end

return M
