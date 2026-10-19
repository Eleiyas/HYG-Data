local M = G.Class("NpcClothConfirmDetailItem", G.UIBase)
local base = G.UIBase

local function clamp_num(num, max_num)
  max_num = math.max(tonumber(max_num) or 1, 1)
  num = tonumber(num) or 1
  if num < 1 then
    return 1
  end
  if max_num < num then
    return max_num
  end
  return math.floor(num)
end

function M:init()
  base.init(self)
  self._num = 1
  self._max_num = 1
  self._is_refreshing_input = false
  self._can_add_callback = nil
  self._affordable_max_callback = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_minus) then
    self:bind_callback(self._btn_minus, pack(self, M._on_btn_minus_click))
  end
  if not is_null(self._btn_add) then
    self:bind_callback(self._btn_add, pack(self, M._on_btn_add_click))
  end
  if not is_null(self._btn_delete) then
    self:bind_callback(self._btn_delete, pack(self, M._on_btn_delete_click))
  end
  if not is_null(self._input_num) then
    self:bind_value_change_action(self._input_num, pack(self, M._on_input_num_changed))
  end
end

function M:refresh(data)
  data = data or {}
  self._item_key = data.key
  self._num = clamp_num(data.num, data.max_num)
  self._max_num = math.max(tonumber(data.max_num) or 1, 1)
  self._change_num_callback = data.on_change_num
  self._delete_callback = data.on_delete
  self._can_add_callback = data.on_query_can_add
  self._affordable_max_callback = data.on_query_affordable_max
  self._item_cfg = item_module:get_cfg_by_id(data.item_id or 0)
  self:set_active(self._item_cfg ~= nil)
  if self._item_cfg == nil then
    return
  end
  self:_refresh_item_info(data.unit_price or 0)
  self:_refresh_num_ui()
end

function M:_refresh_item_info(unit_price)
  local item_cfg = self._item_cfg
  if not is_null(self._img_icon) then
    UIUtil.set_image(self._img_icon, item_cfg.tooltableicon or item_cfg.icon, self:get_load_proxy())
  end
  if not is_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, item_cfg.name or "")
  end
  if not is_null(self._txt_coin_num) then
    UIUtil.set_text(self._txt_coin_num, unit_price)
  end
  if not is_null(self._state_group_quality) then
    self._state_group_quality:SetState(item_cfg.rank or 0)
  end
end

function M:_refresh_num_ui()
  self._is_refreshing_input = true
  if not_null(self._txt_num) then
    self._txt_num.text = tostring(self._num)
  end
  self._is_refreshing_input = false
  if not is_null(self._btn_minus) then
    self._btn_minus.interactable = self._num > 1
  end
  if not is_null(self._btn_add) then
    self._btn_add.interactable = self._num < self._max_num
  end
end

function M:_notify_num_changed(num)
  num = clamp_num(num, self._max_num)
  if self._num == num then
    self:_refresh_num_ui()
    return
  end
  self._num = num
  self:_refresh_num_ui()
  if self._change_num_callback then
    self._change_num_callback(self._item_key, num)
  end
end

function M:_on_btn_minus_click()
  self:_notify_num_changed(self._num - 1)
end

function M:_on_btn_add_click()
  local next_num = self._num + 1
  if self._can_add_callback and not self._can_add_callback(self._item_key, next_num) then
    UIUtil.show_tips_by_text_id("NpcCloth_AddGoods_NotEnough")
    return
  end
  self:_notify_num_changed(next_num)
end

function M:_on_btn_delete_click()
  if self._delete_callback then
    self._delete_callback(self._item_key)
  end
end

function M:_on_input_num_changed(text)
  if self._is_refreshing_input then
    return
  end
  local num = tonumber(text)
  if num == nil then
    return
  end
  num = clamp_num(num, self._max_num)
  if self._affordable_max_callback then
    local affordable = self._affordable_max_callback(self._item_key) or self._max_num
    if num > affordable then
      num = affordable
      UIUtil.show_tips_by_text_id("Item_CoinIsDeficiency")
    end
  end
  self:_notify_num_changed(num)
end

return M
