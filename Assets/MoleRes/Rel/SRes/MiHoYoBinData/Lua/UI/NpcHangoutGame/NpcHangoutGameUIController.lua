local M = G.Class("NpcHangoutGameUIController")
local title_mode_score = 1
local content_mode_countdown = 1
local score_delta_duration = 2
local text_key = {
  abandon_title = "NpcHangoutGame_Abandon_Title",
  abandon_content = "NpcHangoutGame_Abandon_Content",
  leave_unstarted_title = "NpcHangoutGame_Leave_Unstarted_Title",
  leave_unstarted_content = "NpcHangoutGame_Leave_Unstarted_Content"
}
local text_arg_source = {
  npc_name = 0,
  player_score = 1,
  npc_score = 2,
  player_catch_count = 3,
  npc_catch_count = 4,
  remain_time = 5
}

local function get_mode_id(cfg, status)
  if is_null(cfg) or is_null(cfg.stageModes) then
    return nil
  end
  for i = 0, cfg.stageModes.Count - 1 do
    local stage = cfg.stageModes[i]
    if stage.StatusValue == status then
      return stage.uiModeId
    end
  end
  return nil
end

local function format_time(seconds)
  local safe_seconds = math.max(0, math.floor(seconds or 0))
  return string.format("%02d:%02d", math.floor(safe_seconds / 60), safe_seconds % 60)
end

local function get_score_delta_text(score_delta)
  if score_delta == 0 then
    return ""
  end
  return (0 < score_delta and "+" or "") .. tostring(score_delta)
end

local function format_text(text_cfg, sources, data, remain_seconds)
  if is_null(text_cfg) then
    return ""
  end
  if is_null(sources) or sources.Count == 0 then
    return text_cfg:ToStringExplicit()
  end
  local npc_name = npc_module:get_npc_name_by_id(data.npc_id) or ""
  local args = {}
  for i = 0, sources.Count - 1 do
    local source = sources[i]
    if source == text_arg_source.npc_name then
      args[#args + 1] = npc_name
    elseif source == text_arg_source.player_score then
      args[#args + 1] = data.player_score
    elseif source == text_arg_source.npc_score then
      args[#args + 1] = data.npc_score
    elseif source == text_arg_source.player_catch_count then
      args[#args + 1] = data.player_catch_count
    elseif source == text_arg_source.npc_catch_count then
      args[#args + 1] = data.npc_catch_count
    elseif source == text_arg_source.remain_time then
      args[#args + 1] = format_time(remain_seconds or data.remain_seconds)
    end
  end
  return text_cfg:ToStringExplicitWithParams(table.unpack(args))
end

function M:__ctor()
  self._hangout_id = nil
  self._render_data = nil
  self._previous_scores = {}
  self._countdown_anchor_seconds = 0
  self._countdown_anchor_time = 0
  self._score_delta_version = 0
end

function M:close()
  self:_hide_panel()
  self._hangout_id = nil
  self._render_data = nil
  self._countdown_anchor_seconds = 0
  self._countdown_anchor_time = 0
  table.clear(self._previous_scores)
end

function M:refresh(hangout_id)
  local context = CsNpcHangoutGameManagerUtil.GetUIContext(hangout_id)
  if is_null(context) or context.status ~= npc_hangout_game_module.npc_hangout_game_status.Started and context.status ~= npc_hangout_game_module.npc_hangout_game_status.ContestEnd then
    if self._hangout_id == hangout_id then
      self:_hide_panel()
      self._hangout_id = nil
      self._render_data = nil
      self._previous_scores[hangout_id] = nil
    end
    return
  end
  local data = {
    npc_id = context.npcId,
    status = context.status,
    player_score = context.playerScore,
    npc_score = context.npcScore,
    player_catch_count = context.playerCatchCount,
    npc_catch_count = context.npcCatchCount,
    remain_seconds = context.remainSeconds
  }
  local game_cfg = LocalDataUtil.get_value(typeof(NpcHangoutGameUICfg), hangout_id)
  local mode_id = get_mode_id(game_cfg, data.status)
  local mode_cfg = mode_id and LocalDataUtil.get_value(typeof(NpcHangoutUIModeCfg), mode_id) or nil
  if is_null(game_cfg) or is_null(mode_cfg) then
    Logger.LogError("[NpcHangoutGame] missing side panel cfg, hangout_id=" .. tostring(hangout_id))
    self:_hide_panel()
    return
  end
  local now = Time.realtimeSinceStartup
  local previous_score = self._previous_scores[hangout_id]
  local score_delta = 0
  local score_delta_base, score_delta_expire_time
  local score_delta_version = self._score_delta_version
  local mode_changed = self._hangout_id == hangout_id and self._render_data and self._render_data.ui_mode_id ~= mode_id
  if mode_cfg.titleMode == title_mode_score and previous_score and data.player_score ~= previous_score and not mode_changed then
    score_delta = data.player_score - previous_score
    score_delta_base = previous_score
    score_delta_expire_time = now + score_delta_duration
    self._score_delta_version = self._score_delta_version + 1
    score_delta_version = self._score_delta_version
  elseif self._hangout_id == hangout_id and self._render_data and self._render_data.score_delta_expire_time and now < self._render_data.score_delta_expire_time and self._render_data.ui_mode_id == mode_id and mode_cfg.titleMode == title_mode_score then
    score_delta = self._render_data.score_delta
    score_delta_base = self._render_data.score_delta_base
    score_delta_expire_time = self._render_data.score_delta_expire_time
    score_delta_version = self._render_data.score_delta_version
  end
  local title_data = data
  if score_delta_base ~= nil then
    title_data = {}
    for key, value in pairs(data) do
      title_data[key] = value
    end
    title_data.player_score = score_delta_base
  end
  local final_title = format_text(mode_cfg.titleText, mode_cfg.titleFormatArgs, data)
  local title = format_text(mode_cfg.titleText, mode_cfg.titleFormatArgs, title_data) .. get_score_delta_text(score_delta)
  self._previous_scores[hangout_id] = data.player_score
  self._hangout_id = hangout_id
  self._countdown_anchor_seconds = data.remain_seconds
  self._countdown_anchor_time = now
  self._render_data = {
    hangout_id = hangout_id,
    ui_mode_id = mode_id,
    feature_icon = game_cfg.featureIcon,
    title = title,
    final_title = final_title,
    score_delta_base = score_delta_base,
    score_delta_expire_time = score_delta_expire_time,
    score_delta_version = score_delta_version,
    content = format_text(mode_cfg.contentText, mode_cfg.contentFormatArgs, data, data.remain_seconds),
    content_text_cfg = mode_cfg.contentText,
    content_format_args = mode_cfg.contentFormatArgs,
    format_data = data,
    title_mode = mode_cfg.titleMode,
    content_mode = mode_cfg.contentMode,
    player_score = data.player_score,
    score_delta = score_delta,
    remain_seconds = data.remain_seconds,
    show_button = mode_cfg.showButton,
    button_text = not_null(mode_cfg.buttonText) and mode_cfg.buttonText:ToStringExplicit() or ""
  }
  lua_event_module:send_event(lua_event_module.event_type.refresh_main_page_panel, MainPanelType.NpcHangoutGame, true)
end

function M:sync_side_panel_state()
  local is_active = false
  if self._hangout_id ~= nil and self._render_data ~= nil then
    local context = CsNpcHangoutGameManagerUtil.GetUIContext(self._hangout_id)
    is_active = not_null(context) and (context.status == npc_hangout_game_module.npc_hangout_game_status.Started or context.status == npc_hangout_game_module.npc_hangout_game_status.ContestEnd)
  end
  lua_event_module:send_event(lua_event_module.event_type.refresh_main_page_panel, MainPanelType.NpcHangoutGame, is_active)
end

function M:on_game_removed(hangout_id)
  self._previous_scores[hangout_id] = nil
  if self._hangout_id == hangout_id then
    self:_hide_panel()
    self._hangout_id = nil
    self._render_data = nil
  end
end

function M:get_render_data()
  if self._render_data and self._render_data.content_mode == content_mode_countdown then
    local elapsed = math.floor(Time.realtimeSinceStartup - self._countdown_anchor_time)
    local remain_seconds = math.max(0, self._countdown_anchor_seconds - elapsed)
    self._render_data.remain_seconds = remain_seconds
    self._render_data.content = format_text(self._render_data.content_text_cfg, self._render_data.content_format_args, self._render_data.format_data, remain_seconds)
  end
  return self._render_data
end

function M:show_unstarted_leave_confirm(yes_callback)
  local hangout_id = CsNpcHangoutGameManagerUtil.GetFirstUnstartedHangoutId()
  if hangout_id == 0 then
    return false
  end
  local context = CsNpcHangoutGameManagerUtil.GetUIContext(hangout_id)
  if is_null(context) then
    return false
  end
  local npc_id = context.npcId
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id)
  common_ui_module:show_icon_confirm_dialog(not_null(npc_cfg) and npc_cfg.iconnamesmall or "", UIUtil.get_text_by_id(text_key.leave_unstarted_title), UIUtil.get_text_by_id(text_key.leave_unstarted_content, npc_module:get_npc_name_by_id(npc_id) or ""), nil, yes_callback)
  return true
end

function M:request_abandon()
  if self._hangout_id == nil then
    return
  end
  local context = CsNpcHangoutGameManagerUtil.GetUIContext(self._hangout_id)
  if is_null(context) or context.status ~= npc_hangout_game_module.npc_hangout_game_status.Started then
    return
  end
  local hangout_id = self._hangout_id
  local cfg = LocalDataUtil.get_value(typeof(NpcHangoutGameUICfg), hangout_id)
  local npc_name = npc_module:get_npc_name_by_id(context.npcId) or ""
  local game_name = not_null(cfg) and not_null(cfg.name) and cfg.name:ToStringExplicit() or ""
  common_ui_module:show_icon_confirm_dialog(not_null(cfg) and cfg.featureIcon or "", UIUtil.get_text_by_id(text_key.abandon_title), UIUtil.get_text_by_id(text_key.abandon_content, npc_name, game_name), nil, function()
    CsNpcHangoutGameManagerUtil.RequestFailFromUI(hangout_id, function(success)
      if not success then
        Logger.LogError("[NpcHangoutGame] RequestFail failed, hangout_id=" .. tostring(hangout_id))
      end
    end)
  end)
end

function M:_hide_panel()
  lua_event_module:send_event(lua_event_module.event_type.refresh_main_page_panel, MainPanelType.NpcHangoutGame, false)
end

return M
