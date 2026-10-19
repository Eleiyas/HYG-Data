click_and_long_press_flow = click_and_long_press_flow or {}
local delay_key = 0.2
local delay_pointer = 0.2
local behavior

local function get_behavior()
  if behavior == nil then
    behavior = player_controller_module.click_and_long_press_behavior
  end
  return behavior
end

function click_and_long_press_flow:_get_delay()
  if self._source == "pointer" then
    return delay_pointer
  end
  return delay_key
end

function click_and_long_press_flow:_read_level()
  if self._source == "key" then
    return player_controller.values._inter_action_down or player_controller.values._inter_action_pressing
  end
  local item = self._item
  return item ~= nil and item:is_pointer_pressed() == true
end

function click_and_long_press_flow:_send_phase(behavior_type)
  local interaction_data = self._data
  if interaction_data == nil then
    return
  end
  local tag_id = interaction_data.tag and interaction_data.tag.TagId or 0
  CsUIUtil.OnOptionItemPhase(interaction_data.entity_guid or 0, tag_id, behavior_type - 1)
  if behavior_type == get_behavior().press_down then
    self._down_sent = true
  end
end

function click_and_long_press_flow:_finish(behavior_type)
  self:_send_phase(behavior_type)
  if self._source == "key" then
    player_controller.values._click_and_long_press_consumed_up = true
  end
  self._data = nil
  self._down_sent = false
  self._elapsed = 0
end

function click_and_long_press_flow:_clear_hold()
  self._is_held = false
  self._item = nil
  self._source = nil
end

function click_and_long_press_flow:begin(data, item, source)
  if self._data ~= nil or self._is_held then
    return
  end
  if data == nil or not data.is_click_and_long_press then
    return
  end
  if source == "pointer" and item == nil then
    return
  end
  self._data = data
  self._item = item
  self._source = source
  self._elapsed = 0
  self._is_held = true
  self._down_sent = false
  player_controller_module:set_selected_interaction(data, item)
  if item ~= nil then
    item:press_with_audio()
  else
    CsUIUtil.OnOptionItemClick(data.arg_type, data.numArg)
  end
  if self._data ~= data then
    local tag_id = data.tag and data.tag.TagId or 0
    local b = get_behavior()
    CsUIUtil.OnOptionItemPhase(data.entity_guid or 0, tag_id, b.press_down - 1)
    CsUIUtil.OnOptionItemPhase(data.entity_guid or 0, tag_id, b.short_press - 1)
    return
  end
  self:_send_phase(get_behavior().press_down)
end

function click_and_long_press_flow:tick(delta_time)
  if self._data == nil and not self._is_held then
    return
  end
  self._is_held = self:_read_level()
  if self._data == nil then
    if not self._is_held then
      self:_clear_hold()
    end
    return
  end
  if player_controller_module:get_selected_interaction_data() ~= self._data then
    self:abort()
    return
  end
  self._elapsed = self._elapsed + (delta_time or 0)
  local press_time = self._data.press_time or 0
  if 0 < press_time and self._elapsed > press_time + self:_get_delay() then
    self:_finish(get_behavior().long_press)
    if not self._is_held then
      self:_clear_hold()
    end
    return
  end
  if not self._is_held then
    self:_finish(get_behavior().short_press)
    self:_clear_hold()
  end
end

function click_and_long_press_flow:abort(item)
  if self._data == nil and not self._is_held then
    return
  end
  if item ~= nil and self._item ~= item then
    return
  end
  if self._data ~= nil and self._down_sent then
    self:_send_phase(get_behavior().short_press)
  end
  self._data = nil
  self._down_sent = false
  self._elapsed = 0
  if item == nil then
    self:_clear_hold()
  elseif not self:_read_level() then
    self:_clear_hold()
  else
    self._is_held = true
  end
end

function click_and_long_press_flow:is_active()
  return self._data ~= nil
end

function click_and_long_press_flow:is_held()
  return self._is_held == true
end

function click_and_long_press_flow:get_item()
  return self._item
end

function click_and_long_press_flow:get_data()
  return self._data
end

function click_and_long_press_flow:get_progress_ratio(data)
  if self._data == nil or self._data ~= data then
    return nil
  end
  local max_time = data.press_time
  if not max_time or max_time <= 0 then
    return nil
  end
  local shown = self._elapsed - self:_get_delay()
  if shown < 0 then
    return nil
  end
  if max_time <= shown then
    return 1
  end
  return shown / max_time
end

return click_and_long_press_flow
