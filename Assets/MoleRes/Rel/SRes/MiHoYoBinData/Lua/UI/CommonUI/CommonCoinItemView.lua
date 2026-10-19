local M = G.Class("CommonCoinItemView", G.UIBase)
local base = G.UIBase
local ABBREV_MIN_VALUE = 1000000

function M:init()
  base.init(self)
  self._coin_id = 0
  self._coin_list = nil
  self._cur_coin_num = 0
  self._auto_update = true
  self._mute_audio = false
  self._anim_time = 0
  self._show_detail = false
  self._on_coin_click = nil
  self._on_add_click = nil
  self._get_num_func = nil
  self._extra_events = nil
  self._dt = nil
  self._update_listener = nil
  self._extra_event_handler = nil
  self._img_coin_icon = nil
  self._txt_coin_num = nil
  self._btn_coin = nil
  self._btn_add = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_coin, pack(self, M._on_btn_coin_click))
  self:bind_callback(self._btn_add, pack(self, M._on_btn_add_click))
  local extra_data = self:get_extra_data()
  if extra_data then
    self:set_data(extra_data)
    self._skip_first_enable = true
  end
end

function M:on_enable()
  base.on_enable(self)
  if self._skip_first_enable then
    self._skip_first_enable = false
    return
  end
  if self._coin_id > 0 then
    self:refresh()
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_kill_tween()
end

function M:on_destroy()
  self:_kill_tween()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:set_data(data)
  if not (not is_null(data) and data.coin_id) or data.coin_id <= 0 then
    return
  end
  self._coin_id = data.coin_id
  self._coin_list = data.coin_list
  self._auto_update = data.auto_update ~= false
  self._mute_audio = data.mute_audio == true
  self._anim_time = data.anim_time or 0
  if is_null(data.show_detail) then
    self._show_detail = true
  else
    self._show_detail = data.show_detail
  end
  self._on_coin_click = data.on_coin_click
  self._on_add_click = data.on_add_click
  self._get_num_func = data.get_num_func
  if self._auto_update then
    self:_ensure_update_listener()
  else
    self:_remove_update_listener()
  end
  self:_register_extra_events(data.extra_events)
  self:refresh()
end

function M:refresh()
  if self._coin_id <= 0 then
    return
  end
  if not_null(self._img_coin_icon) then
    self:_refresh_icon()
  end
  self._cur_coin_num = self:_get_num()
  if not_null(self._txt_coin_num) then
    UIUtil.set_text(self._txt_coin_num, self:_format_num(self._cur_coin_num))
  end
end

function M:_format_num(num)
  if num < ABBREV_MIN_VALUE then
    local language_type_value = LocManagerIns:get_cur_lan_type()
    if language_type_value == LanguageType.LanguageSc then
      return num
    end
    return TextMapFormatUtil.FormatInteger(num, language_type_value)
  end
  return TextMapFormatUtil.FormatAbbreviation(num)
end

function M:get_coin_num()
  return self._cur_coin_num
end

function M:set_coin_id(coin_id)
  if not coin_id or coin_id <= 0 then
    return
  end
  self._coin_id = coin_id
  self:refresh()
end

function M:animated_refresh(anim_time, mute_audio)
  self:_update_num(anim_time or self._anim_time, mute_audio == true)
end

function M:_refresh_icon()
  item_module:set_item_icon(self._img_coin_icon, self._coin_id, nil, nil, self:get_load_proxy())
end

function M:_get_num()
  if self._get_num_func then
    return self._get_num_func()
  end
  return back_bag_module:get_coin_or_item_num(self._coin_id)
end

function M:_get_item_info_dialog_data()
  local data_list = {}
  for _, coin_id in ipairs(self._coin_list) do
    if coin_id and 0 < coin_id then
      data_list[#data_list + 1] = {
        cfg_id = coin_id,
        num = back_bag_module:get_coin_or_item_num(coin_id)
      }
    end
  end
  return data_list
end

function M:_update_num(anim_time, mute_audio)
  self:_kill_tween()
  local new_num = self:_get_num()
  local is_add = new_num > self._cur_coin_num
  if anim_time and 0 < anim_time then
    if not mute_audio then
      self:_play_audio(is_add and UAudioGroup.CoinAddStart or UAudioGroup.CoinSubtractStart)
    end
    self._dt = DOTween.To(function(value)
      if not is_null(self._txt_coin_num) then
        UIUtil.set_text(self._txt_coin_num, self:_format_num(math.ceil(value)))
      end
    end, self._cur_coin_num, new_num, anim_time):OnComplete(function()
      self._cur_coin_num = new_num
      if not_null(self._txt_coin_num) then
        UIUtil.set_text(self._txt_coin_num, self:_format_num(self._cur_coin_num))
      end
      if not mute_audio then
        self:_play_audio(is_add and UAudioGroup.CoinAddEnd or UAudioGroup.CoinSubtractEnd)
      end
      self._dt = nil
    end)
  else
    if not mute_audio and self._cur_coin_num ~= new_num then
      self:_play_audio(is_add and UAudioGroup.CoinAddEnd or UAudioGroup.CoinSubtractEnd)
    end
    self._cur_coin_num = new_num
    if not_null(self._txt_coin_num) then
      UIUtil.set_text(self._txt_coin_num, self:_format_num(self._cur_coin_num))
    end
  end
end

function M:_on_btn_coin_click()
  if self._coin_id <= 0 then
    return
  end
  if self._on_coin_click then
    self._on_coin_click(self._coin_id, self._cur_coin_num)
    return
  end
  if self._show_detail then
    if self._coin_list and 0 < #self._coin_list then
      item_module:open_item_info_dialog_list(self:_get_item_info_dialog_data(), self._coin_id)
    else
      item_module:open_item_info_dialog(self._coin_id, back_bag_module:get_coin_or_item_num(self._coin_id))
    end
  end
end

function M:_on_btn_add_click()
  if self._coin_id <= 0 then
    return
  end
  if self._on_add_click then
    self._on_add_click(self._coin_id, self._cur_coin_num)
  end
end

function M:_play_audio(audio_group)
  local wEvent = CsUIUtil.GetUnionAudioConfigByConfigId(audio_group, self._coin_id)
  if not is_null(wEvent) and wEvent ~= 0 then
    CsAudioManagerUtil.PlaySFX(wEvent)
  end
end

function M:_kill_tween()
  if self._dt then
    self._dt:OnComplete(nil)
    self._dt:Kill()
    self._dt = nil
  end
end

function M:_ensure_update_listener()
  if self._update_listener then
    return
  end
  
  function self._update_listener(virtual_item)
    if is_null(virtual_item) then
      return
    end
    if virtual_item.ConFigID == self._coin_id then
      self:_update_num(self._anim_time, self._mute_audio)
    end
  end
  
  self:add_evt_listener(EventID.UpdateCoinData, self._update_listener)
end

function M:_remove_update_listener()
  if not self._update_listener then
    return
  end
  self:remove_evt_listener(EventID.UpdateCoinData)
  self._update_listener = nil
end

function M:_register_extra_events(extra_events)
  if self._extra_events then
    for _, event_id in ipairs(self._extra_events) do
      self:remove_evt_listener(event_id)
    end
    self._extra_events = nil
  end
  if not extra_events or #extra_events == 0 then
    return
  end
  local seen = {}
  local dedup = {}
  for _, event_id in ipairs(extra_events) do
    if event_id and not seen[event_id] then
      seen[event_id] = true
      table.insert(dedup, event_id)
    end
  end
  if not self._extra_event_handler then
    function self._extra_event_handler()
      if self._coin_id > 0 then
        self:_update_num(self._anim_time, self._mute_audio)
      end
    end
  end
  self._extra_events = dedup
  for _, event_id in ipairs(dedup) do
    self:add_evt_listener(event_id, self._extra_event_handler)
  end
end

function M:set_show_add(show_add)
  if is_null(self._btn_add) then
    return
  end
  UIUtil.set_active(self._btn_add, show_add)
end

return M
