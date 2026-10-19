local M = G.Class("PlanetMemoirsPage", G.UIWindow)
local base = G.UIWindow
local planet_memoirs_info_panel_class_name = "UI/PlanetMemoirs/PlanetMemoirsInfoPanel"
local info_group_size = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PlanetMemoirs/PlanetMemoirsPage"
  self.config.type = EUIType.Page
  self._info_panels = {}
  self._info_cfgs = {}
  self._summary_cfgs = {}
  self._cur_info_index = 1
  self._waiting = false
  self._wait_duration = 0
  self._wait_elapsed = 0
  self._wait_callback = nil
  self._group_show_time = 0
  self._fade_in_time = 0
  self._fade_out_time = 0
  self._summarize_fading = false
  self._summarize_fade_dur = 0
  self._summarize_fade_t = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._info_panels[1] = self:add_panel(planet_memoirs_info_panel_class_name, self._trans_info_1)
  self._info_panels[2] = self:add_panel(planet_memoirs_info_panel_class_name, self._trans_info_2)
  self._info_panels[3] = self:add_panel(planet_memoirs_info_panel_class_name, self._trans_info_3)
end

function M:on_enable()
  base.on_enable(self)
  self._btn_close.interactable = false
  self._canvas_group_summarize.alpha = 0
  UIUtil.set_active(self._trans_icon_arrow, false)
  self:_apply_extra_data()
  self:_load_cfgs()
  self:_show_infos()
  self:_play_next_group()
end

function M:_apply_extra_data()
  self._on_memoirs_complete = nil
  local extra = self:get_extra_data()
  if extra == nil then
    return
  end
  self._group_show_time = extra.groupShowTime or 3
  self._fade_in_time = extra.fadeInTime or 0.5
  self._fade_out_time = extra.fadeOutTime or 0.5
  self._on_memoirs_complete = extra.onComplete
  if extra.typewriterSpeed ~= nil and extra.typewriterSpeed > 0 and not_null(self._typewriter_summarize) then
    self._typewriter_summarize:SetSecondPerChar(extra.typewriterSpeed)
  end
end

function M:on_disable()
  base.on_disable(self)
  if self._typewriter_summarize then
    self._typewriter_summarize:ClearAction()
  end
  self:_cancel_pending_step()
  self:_invoke_memoirs_complete()
end

function M:close_self()
  self:_cancel_pending_step()
  base.close_self(self)
end

function M:_invoke_memoirs_complete()
  if self._on_memoirs_complete == nil then
    return
  end
  local cb = self._on_memoirs_complete
  self._on_memoirs_complete = nil
  if cb ~= nil then
    cb()
  end
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._waiting then
    self._wait_elapsed = self._wait_elapsed + deltaTime
    if self._wait_elapsed >= self._wait_duration then
      self._waiting = false
      local cb = self._wait_callback
      self._wait_callback = nil
      if cb ~= nil then
        cb()
      end
    end
  end
  if self._summarize_fading then
    self._summarize_fade_t = self._summarize_fade_t + deltaTime
    local t = self._summarize_fade_t / self._summarize_fade_dur
    if 1 <= t then
      t = 1
      self._summarize_fading = false
    end
    self._canvas_group_summarize.alpha = t
  end
end

function M:_show_infos()
  UIUtil.set_active(self._trans_infos, true)
  UIUtil.set_active(self._trans_summarize, false)
  UIUtil.set_active(self._btn_close, false)
  for i = 1, info_group_size do
    if self._info_panels[i] then
      self._info_panels[i]:show(false)
    end
  end
  self._cur_info_index = 1
end

function M:_show_summarize()
  UIUtil.set_active(self._trans_infos, false)
  UIUtil.set_active(self._trans_summarize, true)
  UIUtil.set_active(self._btn_close, true)
  self._btn_close.interactable = false
  self._canvas_group_summarize.alpha = 0
  if 0 < self._fade_in_time then
    self._summarize_fade_dur = self._fade_in_time
    self._summarize_fade_t = 0
    self._summarize_fading = true
  else
    self._canvas_group_summarize.alpha = 1
    self._summarize_fading = false
  end
  local summary_text = self:_compose_summary_text()
  UIUtil.set_text(self._txt_summarize, summary_text)
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_summarize_txt)
  if not_null(self._typewriter_summarize) then
    self._typewriter_summarize:ClearAction()
    self._typewriter_summarize:PlayTypewriterAnim(function()
      self:_on_summarize_typewriter_complete()
    end)
  else
    self:_on_summarize_typewriter_complete()
  end
end

function M:_on_summarize_typewriter_complete()
  self._btn_close.interactable = true
  UIUtil.set_active(self._trans_icon_arrow, true)
end

function M:_play_next_group()
  if self._cur_info_index > #self._info_cfgs then
    self:_show_summarize()
    return
  end
  local active_count = 0
  for i = 1, info_group_size do
    if self._info_panels[i] then
      local cfg = self._info_cfgs[self._cur_info_index + i - 1]
      self._info_panels[i]:refresh_view(cfg, 0)
      if cfg then
        active_count = active_count + 1
      end
    end
  end
  self._cur_info_index = self._cur_info_index + info_group_size
  if active_count == 0 then
    self:_show_summarize()
    return
  end
  self:_fade_infos(1, self._fade_in_time, function()
    self:_wait_then(self._group_show_time, function()
      self:_fade_infos(0, self._fade_out_time, function()
        self:_play_next_group()
      end)
    end)
  end)
end

function M:_fade_infos(target_alpha, duration, on_complete)
  self:_cancel_pending_step()
  local active_panels = {}
  for i = 1, info_group_size do
    local panel = self._info_panels[i]
    if panel and panel.is_active then
      table.insert(active_panels, panel)
    end
  end
  local count = #active_panels
  if count == 0 then
    if on_complete ~= nil then
      on_complete()
    end
    return
  end
  
  local function play_one_info(idx)
    local is_last = idx == count
    active_panels[idx]:fade_to(target_alpha, duration, function()
      if is_last then
        if on_complete ~= nil then
          on_complete()
        end
      else
        play_one_info(idx + 1)
      end
    end)
  end
  
  play_one_info(1)
end

function M:_wait_then(seconds, on_complete)
  self:_cancel_pending_step()
  if seconds == nil or seconds <= 0 then
    if on_complete ~= nil then
      on_complete()
    end
    return
  end
  self._wait_duration = seconds
  self._wait_elapsed = 0
  self._wait_callback = on_complete
  self._waiting = true
end

function M:_cancel_pending_step()
  self._waiting = false
  self._wait_callback = nil
  self._summarize_fading = false
  for i = 1, info_group_size do
    local panel = self._info_panels[i]
    if panel and panel.stop_fade ~= nil then
      panel:stop_fade()
    end
  end
end

function M:_compose_summary_text()
  local lines = {}
  for _, cfg in ipairs(self._summary_cfgs) do
    local line = self:_compose_summary_line(cfg)
    if line ~= nil and line ~= "" then
      table.insert(lines, line)
    end
  end
  return table.concat(lines, [[


]])
end

function M:_compose_summary_line(cfg)
  if cfg == nil or cfg.description == nil then
    return ""
  end
  local args = {}
  local list_len = cfg.trackeridlistLength or 0
  for i = 0, list_len - 1 do
    local tid = cfg:trackeridlist(i)
    args[i + 1] = tostring(self:_get_tracker_count(tid))
  end
  return UIUtil.get_text_by_id(cfg.description, table.unpack(args))
end

function M:_get_tracker_count(tracker_id)
  if tracker_id == nil or tracker_id == 0 then
    return 0
  end
  return CsGameplayUtilitiesTrackerUtil.GetTrackerTriggerCount(tracker_id) or 0
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_close_btn_click))
end

function M:_on_close_btn_click()
  self:close_self()
end

function M:_load_cfgs()
  self._info_cfgs = self:_to_sorted_list(ExcelDataUtil.get_table(typeof(BPlanetMemoirsCfg)))
  self._summary_cfgs = self:_to_sorted_list(ExcelDataUtil.get_table(typeof(BPlanetMemoirsSummaryCfg)))
  local filtered = {}
  for _, cfg in ipairs(self._info_cfgs) do
    if self:_is_tracker_finished(cfg.trackerid) then
      table.insert(filtered, cfg)
    end
  end
  self._info_cfgs = filtered
end

function M:_is_tracker_finished(tracker_id)
  if tracker_id == nil or tracker_id == 0 then
    return false
  end
  local finish_time = CsGameplayUtilitiesTrackerUtil.GetTrackerTriggerFinishTime(tracker_id) or 0
  return 0 < finish_time
end

function M:_to_sorted_list(cfg_table)
  local list = {}
  if cfg_table == nil then
    return list
  end
  for _, cfg in pairs(cfg_table) do
    if not_null(cfg) then
      table.insert(list, cfg)
    end
  end
  table.sort(list, function(a, b)
    return (a.id or 0) < (b.id or 0)
  end)
  return list
end

function M:_gen_info_for_test()
  if self._info_cfgs == nil or #self._info_cfgs < 1 then
    return
  end
  local sample = self._info_cfgs[1]
  local fake_list = {}
  for i = 1, 10 do
    fake_list[i] = sample
  end
  self._info_cfgs = fake_list
end

function M:_get_text(text_id, values)
  local txt = UIUtil.get_text_by_id(text_id, table.unpack(values))
  if not string.is_valid(txt) then
    txt = text_id
  end
  return txt
end

return M
