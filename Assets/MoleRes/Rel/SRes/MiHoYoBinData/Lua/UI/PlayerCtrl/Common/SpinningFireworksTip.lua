local refresh_amount_interval = 0.2
local M = G.Class("SpinningFireworksTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase

function M:init()
  base.init(self)
  self._is_holding = false
  self._hold_elapsed = 0
  self._hold_max = 0
  self._handed_item_id = 0
  self._active_amount = false
  self._last_count = -1
  self._refresh_amount_timer = 0
  self._is_destructible_handheld = false
  self._last_destructible_count = 0
  self._last_destructible_max_count = 0
  self._item_max_use_times_cache = {}
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._progress_long_press) then
    UIUtil.set_active(self._progress_long_press, true)
  end
  self:_apply_progress(0)
  if self._obj_amount then
    UIUtil.set_active(self._obj_amount, false)
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_reset_hold()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnOperationHoldBegin, function(max_charge_time)
    self:_on_hold_begin(max_charge_time)
  end)
  self:add_evt_listener(EventID.OnOperationHoldEnd, function()
    self:_on_hold_end()
  end)
  self:add_evt_listener(EventID.LuaCutPlayerEquipTool, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.LuaSetActionBtnState, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.OnHoldingHandModuleDataUpdate, function()
    self:refresh()
  end)
end

function M:update(deltaTime)
  if self._is_holding then
    self._hold_elapsed = self._hold_elapsed + deltaTime
    self:_apply_progress(self:_calc_ratio())
  end
  if self._active_amount then
    self._refresh_amount_timer = self._refresh_amount_timer + deltaTime
    if self._refresh_amount_timer > refresh_amount_interval then
      self._refresh_amount_timer = 0
      local current_count
      if self._is_destructible_handheld then
        current_count = self:_refresh_destructible_count()
      else
        current_count = self:_refresh_count()
      end
      if (current_count or 0) <= 0 then
        self._active_amount = false
        if self._obj_amount then
          UIUtil.set_active(self._obj_amount, false)
        end
      end
    end
  end
end

function M:inner_refresh()
  self._handed_item_id = 0
  if EntityUtil.is_valid(EntityUtil.get_player_entity_guid()) then
    self._handed_item_id = EntityUtil.get_avatar_hand_tool_id(EntityUtil.get_player_entity_guid())
  end
  self._active_amount = false
  self._is_destructible_handheld = false
  if self._obj_amount and self._handed_item_id and self._handed_item_id ~= 0 then
    if 0 < self:_get_destructible_count() then
      self._active_amount = true
      self._is_destructible_handheld = true
      self._last_destructible_count = -1
      self._last_destructible_max_count = -1
      self:_refresh_destructible_count()
    else
      local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), self._handed_item_id)
      if item_cfg ~= nil and item_cfg.stacknum > 1 then
        self._last_count = -1
        local count = self:_refresh_count()
        self._active_amount = 0 < count
      end
    end
  end
  if self._obj_amount then
    UIUtil.set_active(self._obj_amount, self._active_amount)
  end
end

function M:_on_hold_begin(max_charge_time)
  self._hold_max = type(max_charge_time) == "number" and 0 < max_charge_time and max_charge_time or 0
  self._hold_elapsed = 0
  self._is_holding = true
  self:_apply_progress(0)
end

function M:_on_hold_end()
  self:_reset_hold()
end

function M:_reset_hold()
  self._is_holding = false
  self._hold_elapsed = 0
  self._hold_max = 0
  self:_apply_progress(0)
end

function M:_calc_ratio()
  if self._hold_max <= 0 then
    return 0
  end
  local ratio = self._hold_elapsed / self._hold_max
  if 1 < ratio then
    return 1
  end
  return ratio
end

function M:_apply_progress(ratio)
  if is_null(self._progress_long_press) then
    return
  end
  self._progress_long_press:SetProgress(ratio)
end

function M:_refresh_count()
  local count = back_bag_module:get_item_num(self._handed_item_id)
  if self._last_count ~= count then
    self._last_count = count
    if is_null(self._txt_amount) == false then
      if 99 < count then
        UIUtil.set_text(self._txt_amount, "99+")
      else
        UIUtil.set_text(self._txt_amount, tostring(count))
      end
    end
  end
  return count
end

function M:_refresh_destructible_count()
  local remain = self:_get_destructible_count()
  local max_times = self:_get_max_use_times(self._handed_item_id)
  if remain <= 0 or max_times <= 0 then
    return remain
  end
  if self._last_destructible_count ~= remain or self._last_destructible_max_count ~= max_times then
    self._last_destructible_count = remain
    self._last_destructible_max_count = max_times
    if is_null(self._txt_amount) == false then
      UIUtil.set_text(self._txt_amount, tostring(remain) .. "/" .. tostring(max_times))
    end
  end
  return remain
end

function M:_get_destructible_count()
  local player_guid = EntityUtil.get_player_entity_guid()
  if not player_guid or player_guid == 0 then
    return -1
  end
  local ok, tool_info = EntityUtil.try_get_avatar_hand_tool_info(player_guid)
  if not ok or is_null(tool_info) or tool_info.MakeGuid == nil or 0 >= tool_info.MakeGuid then
    return -1
  end
  return CsUIUtil.GetItemRemainUseTimesByMakeGuid(tool_info.MakeGuid)
end

function M:_get_max_use_times(item_id)
  if item_id == nil or item_id == 0 then
    return 0
  end
  if self._item_max_use_times_cache[item_id] then
    return self._item_max_use_times_cache[item_id]
  end
  local id_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), item_id)
  if is_null(id_cfg) or not string.is_valid(id_cfg.holdstyle) then
    self._item_max_use_times_cache[item_id] = 0
    return 0
  end
  local holdable_tag_cfgs = ExcelDataUtil.get_table(typeof(BHoldableTagLookUpCfg))
  local holdstyle = id_cfg.holdstyle
  for _, cfg in pairs(holdable_tag_cfgs) do
    if cfg.holdstyle == holdstyle then
      self._item_max_use_times_cache[item_id] = cfg.usetimes
      return cfg.usetimes
    end
  end
  self._item_max_use_times_cache[item_id] = 0
  return 0
end

return M
