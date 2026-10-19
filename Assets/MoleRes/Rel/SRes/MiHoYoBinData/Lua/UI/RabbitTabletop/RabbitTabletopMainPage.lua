local M = G.Class("RabbitTabletopMainPage", G.UIWindow)
local base = G.UIWindow
local Stage = rabbit_tabletop_module.stage
local ChatState = rabbit_tabletop_module.chat_state
local GameState = rabbit_tabletop_module.game_state
local StepType = TutuCardTurnStepType
local bubble_cls = "UI/RabbitTabletop/RabbitTabletopChatBubble"
local indicate_cls = "UI/RabbitTabletop/RabbitTabletopPlayerIndicate"
local order_avatar_cls = "UI/RabbitTabletop/RabbitTabletopOrderAvatar"
local game_over_tip_cls = "UI/RabbitTabletop/RabbitTabletopGameOverTip"
local WHEEL_COLOR_HIDE_DELAY = 0.5
local LAST_CARD_TIP_COUNT = 1
local BannerState = {
  add_card = 0,
  thunder = 1,
  add_card_result = 2,
  no_judge = 3,
  into_judge = 4,
  safe = 5,
  star_tide = 6,
  normal_play = 7
}
local OrderState = {
  none = 0,
  counterwise = 1,
  clockwise = 2
}
local AvatarItemState = {
  empty = 0,
  seated = 1,
  playing = 2
}
local ScreenEffectState = {
  into_judge = 0,
  hit = 1,
  none = 2
}
local OVERLAY_BANNER_DURATION = {
  [BannerState.add_card_result] = 1.5,
  [BannerState.no_judge] = 1.5,
  [BannerState.safe] = 1.0,
  [BannerState.star_tide] = 1.0
}
local _show_round = false
local BASE_ASPECT = 1.7777777777777777
local MIN_ASPECT = 1
local BASE_INDICATE_Y = 260
local MAX_INDICATE_Y = 650

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopMainPage"
  self.config.type = EUIType.Page
  self._cur_stage = Stage.ready
  self._cur_game_state = GameState.normal
  self._is_chat_open = false
  self._can_start = false
  self._is_start_game = false
  self._last_sync_ctx = nil
  self._tip_queue = {}
  self._chat_bubbles = {}
  self._tip_showing = false
  self._tip_wait_timer = nil
  self._start_tips_delay_timer = nil
  self._current_tip_guid = nil
  self._is_choosing_color = false
  self._wait_rotate_wheel = false
  self._cur_step_payload = nil
  self._last_stacked_draw_count = 0
  self._game_over_tip_guid = nil
  self._last_card_tip_flags = {}
  self._wheel_color_hide_timer = nil
  self._banner_stack = {}
  self._banner_overlay_queue = {}
  self._banner_current = nil
  self._banner_timer = nil
  self._banner_visible = false
  self._order_avatar_items = {}
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = false,
      camera = true,
      ability = false
    }
  }
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._chat_input_field_panel = self:add_panel(chat_module.chat_input_field_panel_cls_name, self._obj_chat_input_field_panel)
  if self._chat_input_field_panel then
    self._chat_input_field_panel:set_reaction_btn_visible(false)
    self._chat_input_field_panel:set_on_send_success_callback(function()
      self:_set_chat_state(false)
    end)
  end
  self._wheel_star_tide = self:add_panel("UI/RabbitTabletop/RabbitTabletopStarTideWheel", self._trans_wheel_star_tide)
  self._wheel_change_color = self:add_panel("UI/RabbitTabletop/RabbitTabletopChangeColorWheel", self._trans_wheel_change_color)
  self._wheel_draw = self:add_panel("UI/RabbitTabletop/RabbitTabletopDrawWheel", self._trans_wheel_draw)
  self._emoji_pool = {
    pool = {},
    active = {}
  }
  self._emoji_cls = "UI/RabbitTabletop/RabbitTabletopEmojiItem"
  UIUtil.set_active(self._obj_emoji_tab, false)
  self._seat_map = {
    [1] = {
      chat_content = self._trans_scroll_chat_bottom,
      indicate_root = self._trans_bottom_indicate_root
    },
    [2] = {
      chat_content = self._trans_scroll_chat_right,
      indicate_root = self._trans_right_indicate_root
    },
    [3] = {
      chat_content = self._trans_scroll_chat_top,
      indicate_root = self._trans_top_indicate_root
    },
    [4] = {
      chat_content = self._trans_scroll_chat_left,
      indicate_root = self._trans_left_indicate_root
    }
  }
  self._chat_bubbles = {}
  for seat_idx, seat in pairs(self._seat_map) do
    self._chat_bubbles[seat_idx] = self:add_panel(bubble_cls, seat.chat_content)
    self._chat_bubbles[seat_idx]:init_pools(self._trans_img_emj_bg, self._trans_item_message)
  end
  self._indicate_items = {}
  self:_init_banner()
  self._uno_constant_cfg = ExcelDataUtil.get_value(typeof(BUnoConstantCfg), 1)
  self._emoji_list = {}
  for i = 1, self._uno_constant_cfg.winnerreactLength do
    table.insert(self._emoji_list, {
      id = self._uno_constant_cfg:winnerreact(i - 1)
    })
  end
end

function M:on_enable()
  base.on_enable(self)
  self._is_chat_open = false
  self:_switch_stage(Stage.ready)
  self:_reset_screen_effect()
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  if extra and extra.owner_guid then
    self._tabletop_guid = extra.owner_guid
  else
    self._tabletop_guid = nil
  end
  rabbit_tabletop_module:set_in_game(true)
  self._waiting_seat = true
  self._waiting_seat_timeout = 3.0
  self._wheel_star_tide:set_active(false)
  self._wheel_draw:set_active(false)
  self._wheel_change_color:set_active(false)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  for _, bubble in pairs(self._chat_bubbles) do
    bubble:update_time(deltaTime)
  end
  self:_tick_countdown_display(deltaTime)
  self:_tick_banner(deltaTime)
  if self._waiting_seat_timeout then
    self._waiting_seat_timeout = self._waiting_seat_timeout - deltaTime
    if self._waiting_seat_timeout <= 0 then
      self._waiting_seat_timeout = nil
      self._waiting_seat = false
    end
  end
  self._wheel_star_tide:tick_spin(deltaTime)
  self._wheel_draw:tick_spin(deltaTime)
  if self._start_tips_delay_timer then
    self._start_tips_delay_timer = self._start_tips_delay_timer - deltaTime
    if 0 >= self._start_tips_delay_timer then
      self._start_tips_delay_timer = nil
      self:_queue_and_play_start_tips()
    end
  end
  if self._tip_wait_timer then
    self._tip_wait_timer = self._tip_wait_timer - deltaTime
    if 0 >= self._tip_wait_timer then
      self._tip_wait_timer = nil
      self:_play_next_tip()
    end
  end
  if self._wheel_color_hide_timer then
    self._wheel_color_hide_timer = self._wheel_color_hide_timer - deltaTime
    if 0 >= self._wheel_color_hide_timer then
      self._wheel_color_hide_timer = nil
      self._wheel_change_color:set_active(false)
    end
  end
  if self._settle_delay_timer then
    self._settle_delay_timer = self._settle_delay_timer - deltaTime
    if 0 >= self._settle_delay_timer then
      self._settle_delay_timer = nil
      self:_close_game_over_tip()
      local winner_uid = self._winner_uid or 0
      if winner_uid ~= 0 and self:_is_player_left(winner_uid) then
        winner_uid = 0
      end
      EventCenter.Broadcast(EventID.TabletopEndGame, winner_uid)
      self:_switch_stage(Stage.settling)
    end
  end
end

function M:on_close()
  base.on_close(self)
  self:_close_game_over_tip()
  rabbit_tabletop_module:set_in_game(false)
  self:_clear_chat_bubbles()
  self:_hide_indicate_items()
  self:_stop_countdown_display()
  self:_clear_tip_queue()
  self._start_tips_delay_timer = nil
  self:_clear_banner_state()
  self._is_choosing_color = false
  self._wait_rotate_wheel = false
  self._cur_step_payload = nil
  self._last_turn_end_round = nil
  self._last_stacked_draw_count = 0
  self._settle_delay_timer = nil
  self._last_card_tip_flags = {}
  self._wheel_color_hide_timer = nil
  self._confirm_popup_guid = nil
  self._last_order_state = nil
  self:_reset_screen_effect()
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, true)
  EventCenter.Broadcast(EventID.LuaTabletopMainPageClosed)
  Logger.Log("[RabbitTabletopMainPage] on_close")
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.TabletopDeskChanged, pack(self, M._on_tabletop_desk_changed))
  self:add_evt_listener(EventID.TabletopPlaySync, pack(self, M._on_tabletop_play_sync))
  self:add_evt_listener(EventID.TabletopSettleGame, pack(self, M._on_tabletop_settle_game))
  self:add_evt_listener(EventID.TabletopUiAction, pack(self, M._on_tabletop_ui_action))
  self:add_evt_listener(EventID.TabletopCloseRabbitMainUI, pack(self, M._on_close_rabbit_main_ui))
  self:add_evt_listener(EventID.TabletopToggleRound, pack(self, M._on_toggle_round))
  self:add_evt_listener(EventIDTags.Tags.eventid_furniture_seat_sitdownfinished, pack(self, M._on_seat_down_finished))
  self:add_lua_listener(lua_event_module.event_type.on_public_chat_ntf, pack(self, M._on_chat_notify))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Esc, self._btn_close_online)
  self:bind_input_and_fun(ActionType.Act.Enter, function()
    if not self._is_chat_open then
      if is_null(self._btn_open_input) or not self._btn_open_input.gameObject.activeSelf then
        return
      end
      self:_set_chat_state(true)
    elseif self._chat_input_field_panel then
      local text = self._chat_input_field_panel:get_input_text()
      if string.is_valid(text) then
        self._chat_input_field_panel:on_enter_click()
      end
    end
  end)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_start, pack(self, M._on_btn_start_click))
  self:bind_callback(self._btn_close_chat_area, pack(self, M._on_btn_close_chat_area_click))
  self:bind_callback(self._btn_open_input, pack(self, M._on_btn_open_input_click))
  self:bind_callback(self._btn_rule, pack(self, M._on_btn_rule_click))
  self:bind_callback(self._btn_draw, pack(self, M._on_btn_draw_click))
  self:bind_callback(self._btn_wheel_star_tide, pack(self, M._on_btn_wheel_star_tide_click))
  self:bind_callback(self._btn_wheel_draw, pack(self, M._on_btn_wheel_draw_click))
  self:bind_callback(self._btn_close_online, pack(self, M._on_btn_close_online_click))
end

function M:reset_state()
  self:_switch_stage(Stage.ready)
end

function M:_switch_stage(stage)
  self._cur_stage = stage
  if stage ~= Stage.ending then
    self._state_stage:SetState(stage)
  end
  UIUtil.set_active(self._trans_round, _show_round and stage == Stage.playing)
  if stage == Stage.ready then
    self:_set_camera_control(true)
    UIUtil.set_active(self._trans_touch_input, InputManagerIns:is_touch())
    self:_refresh_ready_stage()
  elseif stage == Stage.dealing then
    self:_set_camera_control(false)
    UIUtil.set_active(self._trans_touch_input, false)
    self:_refresh_dealing_stage()
  elseif stage == Stage.playing then
    self:_refresh_playing_stage()
  elseif stage == Stage.settling then
    self:_refresh_end_stage()
  elseif stage == Stage.ending then
    self:_open_settlement()
  end
end

function M:_set_camera_control(can_move)
  if self.config.player_ctrl_cfg and self.config.player_ctrl_cfg.ctrl_cfg then
    self.config.player_ctrl_cfg.ctrl_cfg.camera = can_move
    player_controller:apply_player_ctrl_cfg(self, self.config.player_ctrl_cfg)
  end
end

function M:_on_tabletop_desk_changed(gameplay_host_guid)
  if gameplay_host_guid ~= self._tabletop_guid then
    return
  end
  local scene_data = CsTabletopGameUtil.GetTabletopGameSceneData(1, self._tabletop_guid)
  if not scene_data then
    return
  end
  if self._cur_stage == Stage.ready then
    self:_refresh_start_btn()
  end
end

function M:_on_tabletop_play_sync(ctx)
  if not ctx or ctx.gameplayHostGuid ~= self._tabletop_guid then
    return
  end
  local prev = self._last_sync_ctx
  self._last_sync_ctx = ctx
  if self:_try_phase_transition(ctx) then
    return
  end
  if self._cur_stage ~= Stage.playing then
    return
  end
  self:_update_player_card_counts()
  self:_refresh_all_indicates()
  self:_refresh_order_direction(ctx)
  self:_handle_turn_step(ctx, prev)
  self:_handle_stacked_draw_diff(ctx)
  if ctx.selfTimeoutCount == 2 and (not prev or prev.selfTimeoutCount < 2) then
    UIUtil.show_tips_by_text_id("Tabletop_Tutupai_Other_NoPlaying")
  end
  self:_try_trigger_screen_effect_debuff(ctx, prev)
end

function M:_try_phase_transition(ctx)
  if ctx.deskPhase == TabletopGameDeskPhase.Dealing and self._cur_stage == Stage.ready then
    self:_switch_stage(Stage.dealing)
    return true
  end
  if ctx.deskPhase == TabletopGameDeskPhase.Playing and self._cur_stage == Stage.dealing then
    self:_switch_stage(Stage.playing)
    return true
  end
  if ctx.deskPhase == TabletopGameDeskPhase.End and self._cur_stage == Stage.settling then
    self:_switch_stage(Stage.ending)
    return true
  end
  return false
end

function M:_handle_turn_step(ctx, prev)
  local step = ctx.currentStep
  if not step then
    return
  end
  local my_uid = player_module:get_player_uid()
  local is_my_turn = ctx.deskCurrentTurnUid == my_uid
  if not prev or prev.turnRoundId ~= ctx.turnRoundId then
    self:_on_turn_changed(ctx)
  end
  self:_dispatch_step(step, ctx, is_my_turn)
end

function M:_on_turn_changed(ctx)
  self._cached_ui_action = nil
  self._cur_step_payload = nil
  self._cur_turn = self:_find_turn_index_by_uid(ctx.deskCurrentTurnUid)
  self:_update_players_afk()
  self:_refresh_all_indicates()
  self:_refresh_order_avatar_items(ctx)
  self:_refresh_round_text(ctx)
end

function M:_dispatch_step(step, ctx, is_my_turn)
  local st = step.StepType
  if st == StepType.TutuCardTurnStepTurnStart then
    if is_my_turn then
      self:_queue_tip("UI/RabbitTabletop/RabbitTabletopStartTip", {
        tips = UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_StartYou"),
        duration = self._uno_constant_cfg.bigtips
      })
      self:_play_tip_queue()
    end
    if ctx.starTideOwnerUid and ctx.starTideOwnerUid > 0 and ctx.starTideOwnerUid == ctx.deskCurrentTurnUid then
      self:_banner_push_overlay(BannerState.no_judge, {
        operator = self:_make_player_brief(ctx.starTideOwnerUid),
        face_kind = TutuCardFaceKind.Wild,
        sub_kind = TutuCardWildKind.StarTide
      })
    end
    self:_set_game_state(GameState.normal)
  elseif st == StepType.TutuCardTurnStepStarTideJudge then
    if step.AllowClientInput then
      self._wait_rotate_wheel = true
      self:_set_game_state(is_my_turn and GameState.wheel_star or GameState.wheel_star_guest)
      self:_banner_push_overlay(BannerState.into_judge, {
        operator = self:_make_player_brief(ctx.starTideOwnerUid),
        face_kind = TutuCardFaceKind.Wild,
        sub_kind = TutuCardWildKind.StarTide
      })
    else
      self._cur_step_payload = step.Payload
      self:trigger_star_tide_spin()
    end
  elseif st == StepType.TutuCardTurnStepPenaltyWheelJudge then
    if step.AllowClientInput then
      self._wait_rotate_wheel = true
      self:_set_game_state(is_my_turn and GameState.wheel_add or GameState.wheel_add_guest)
      local previous_turn = (self._cur_turn + (ctx.isClockwise and 1 or -1)) % #self._players
      self:_banner_push_overlay(BannerState.into_judge, {
        operator = self:_make_player_brief(self._players[previous_turn + 1].uid),
        face_kind = TutuCardFaceKind.Wild,
        sub_kind = TutuCardWildKind.PenaltyWheel
      })
    else
      self._cur_step_payload = step.Payload
      self:trigger_draw_wheel_spin()
    end
  elseif st == StepType.TutuCardTurnStepTakeStackedDraw then
    if is_my_turn then
      local suggested = CsTabletopGameUtil.GetSuggestedPlayCardId(self._tabletop_guid) or 0
      if 0 < suggested then
        self:_set_game_state(GameState.normal, true)
      else
        self:_set_game_state(GameState.cant_play)
      end
    else
      self:_set_game_state(GameState.normal)
    end
  elseif st == StepType.TutuCardTurnStepSkipPresent then
    if is_my_turn then
      self:_set_game_state(GameState.cant_play)
    else
      self:_set_game_state(GameState.normal)
    end
  elseif st == StepType.TutuCardTurnStepChooseColor then
    if step.AllowClientInput then
      self:_on_open_color_choosing()
    else
      local payload = step.Payload
      if payload and payload.ActionKind == TutuCardPlayActionKind.ColorChanged then
        if not is_my_turn or self._is_choosing_color then
          self._wheel_change_color:show_selected_suit(ctx.currentColor)
        end
        self._wheel_color_hide_timer = WHEEL_COLOR_HIDE_DELAY
      end
    end
  elseif st == StepType.TutuCardTurnStepPlay then
    if is_my_turn then
      local suggested = CsTabletopGameUtil.GetSuggestedPlayCardId(self._tabletop_guid) or 0
      if 0 < suggested then
        self:_set_game_state(GameState.normal, true)
      else
        self:_set_game_state(GameState.please_draw_card)
      end
    else
      self:_set_game_state(GameState.normal)
    end
  elseif st == StepType.TutuCardTurnStepTurnEnd then
    local turn_end_key = ctx.turnRoundId
    if self._last_turn_end_round ~= turn_end_key then
      self._last_turn_end_round = turn_end_key
      local payload = step.Payload
      if payload and payload.ActionKind == TutuCardPlayActionKind.PlayCard then
        local card_id = tonumber(payload.PlayedCardId) or 0
        if 0 < card_id then
          self:_on_play_card(payload)
        end
      end
      local operator_uid = payload and payload.OperatorUid or ctx.deskCurrentTurnUid or 0
      self:_check_last_card_tip(operator_uid)
    end
    self:_set_game_state(GameState.normal)
  elseif st == StepType.TutuCardTurnStepDrawCards then
    self:_set_game_state(GameState.normal)
  end
  local cd = step.CountdownMs
  if cd and 0 < cd then
    self:_start_countdown_display(cd / 1000)
  end
end

function M:_update_player_card_counts()
  if not self._players or not self._tabletop_guid then
    return
  end
  for _, p in ipairs(self._players) do
    p.card_count = CsTabletopGameUtil.GetLocalHandCardCount(self._tabletop_guid, p.uid)
    if p.card_count > LAST_CARD_TIP_COUNT then
      self._last_card_tip_flags[p.uid] = nil
    end
  end
end

function M:_check_last_card_tip(uid)
  local target
  for _, p in ipairs(self._players) do
    if p.uid == uid then
      target = p
      break
    end
  end
  if not target then
    return
  end
  if (target.card_count or 0) ~= LAST_CARD_TIP_COUNT then
    return
  end
  if self._last_card_tip_flags[uid] then
    return
  end
  self._last_card_tip_flags[uid] = true
  self:_show_game_over_tip(target.seat_index)
end

function M:_on_tabletop_settle_game(settle_notify)
  if not settle_notify then
    return
  end
  if self._confirm_popup_guid then
    UIManagerInstance:close(self._confirm_popup_guid)
    self._confirm_popup_guid = nil
  end
  local settle_info = settle_notify.SelfSettleInfo
  if not settle_info then
    return
  end
  local reward_items = {}
  local reward_item_map = {}
  
  local function add_reward_item(item_id, item_count)
    if (item_id or 0) <= 0 or (item_count or 0) <= 0 then
      return
    end
    local old_count = reward_item_map[item_id] or 0
    reward_item_map[item_id] = old_count + item_count
  end
  
  local base_reward_count = settle_info.RewardCount or 0
  add_reward_item(back_bag_module.coin_type.galactic_bazaar, base_reward_count)
  local extra_rewards = settle_info.ExtraRewards
  if extra_rewards ~= nil then
    local extra_list = list_to_table(extra_rewards)
    if extra_list ~= nil and 0 < #extra_list then
      for _, extra_reward in ipairs(extra_list) do
        local item_id = extra_reward and extra_reward.ItemId or 0
        local item_count = extra_reward and extra_reward.ItemCount or 0
        add_reward_item(item_id, item_count)
      end
    else
      local extra_count = extra_rewards.Count or extra_rewards.Length or 0
      for i = 0, extra_count - 1 do
        local extra_reward = extra_rewards[i]
        local item_id = extra_reward and extra_reward.ItemId or 0
        local item_count = extra_reward and extra_reward.ItemCount or 0
        add_reward_item(item_id, item_count)
      end
    end
  end
  for item_id, item_count in pairs(reward_item_map) do
    table.insert(reward_items, {cfg_id = item_id, num = item_count})
  end
  local merged_reward_count = reward_item_map[back_bag_module.coin_type.galactic_bazaar] or 0
  self._winner_uid = settle_notify.WinnerUid
  local winner_seat_index
  for _, player in ipairs(self._players or {}) do
    if player.uid == self._winner_uid then
      winner_seat_index = player.seat_index
      break
    end
  end
  self._settle_data = {
    play_card_count = settle_info.PlayCardCount,
    draw_card_count = settle_info.DrawCardCount,
    is_winner = settle_info.IsWinner,
    winner_seat_index = winner_seat_index,
    reward_count = merged_reward_count,
    reward_items = reward_items,
    is_in_metro_scene = settle_notify.IsInMetroScene,
    ready_callback = pack(self, M._on_tabletop_end_game)
  }
  Logger.Log(string.format("[RabbitTabletopMainPage] settle winner=%s base_reward=%s merged_reward=%s reward_items=%s extra_rewards=%s is_in_metro_scene=%s", tostring(self._winner_uid), tostring(base_reward_count), tostring(merged_reward_count), tostring(#reward_items), tostring(extra_rewards ~= nil and (extra_rewards.Count or extra_rewards.Length or 0) or 0), tostring(settle_notify.IsInMetroScene)))
  local amira_time = self._uno_constant_cfg and self._uno_constant_cfg.amiratime or 0
  self._settle_delay_timer = amira_time
end

function M:_show_game_over_tip(seat_index)
  if not seat_index then
    return
  end
  local tip = UIManagerInstance:get_window_by_class(game_over_tip_cls)
  if tip and tip.is_active and tip.refresh_seat and tip:refresh_seat(seat_index) then
    self._game_over_tip_guid = tip.guid
    return
  end
  self._game_over_tip_guid = UIManagerInstance:open(game_over_tip_cls, {seat_index = seat_index})
end

function M:_close_game_over_tip()
  if not self._game_over_tip_guid then
    return
  end
  UIManagerInstance:close(self._game_over_tip_guid)
  self._game_over_tip_guid = nil
end

function M:_on_open_color_choosing()
  self._is_choosing_color = true
  self._wheel_change_color:clear_selected_suit()
  local ctx = self._last_sync_ctx
  local is_my_turn = ctx and ctx.deskCurrentTurnUid == player_module:get_player_uid()
  self:_set_game_state(is_my_turn and GameState.change_color or GameState.change_color_guest)
  self._wheel_change_color:set_active(true)
  self:_banner_push_overlay(BannerState.normal_play, {
    operator = self:_make_player_brief(ctx.deskCurrentTurnUid),
    face_kind = TutuCardFaceKind.Wild,
    sub_kind = TutuCardWildKind.ColorChange
  })
  Logger.Log("[RabbitTabletopMainPage] _on_open_color_choosing")
end

function M:_on_tabletop_end_game(is_ready_for_next_game)
  CsTabletopGameUtil.SendReadyForNextGame(self._tabletop_guid, is_ready_for_next_game)
  if is_ready_for_next_game then
    self:_switch_stage(Stage.ready)
    EventCenter.Broadcast(EventID.TabletopBackToReady)
    return
  end
  self:close_self()
end

function M:choosing_color(color)
  if not self._is_choosing_color then
    return
  end
  self._is_choosing_color = false
  self._wheel_change_color:set_interactable(false)
  Logger.Log(string.format("[RabbitTabletopMainPage] Choosing color: %s", color))
  CsTabletopGameUtil.SendChooseColor(self._tabletop_guid, color)
end

function M:_refresh_ready_stage()
  self._last_sync_ctx = nil
  self._players = nil
  self._last_turn_end_round = nil
  self._last_stacked_draw_count = 0
  self._last_card_tip_flags = {}
  self:_stop_countdown_display()
  self:_clear_banner_state()
  self:_set_chat_state(false)
  UIUtil.set_active(self._btn_open_input, true)
  UIUtil.set_active(self._slider_play, false)
  self._is_start_game = false
  self:_clear_chat_bubbles()
  self:_hide_indicate_items()
  self:_refresh_order_direction(nil)
  self:_refresh_start_btn()
end

function M:_refresh_start_btn()
  local player_count = 0
  if self._tabletop_guid then
    local scene_data = CsTabletopGameUtil.GetTabletopGameSceneData(1, self._tabletop_guid)
    if scene_data then
      for i = 0, scene_data.SeatUids.Length - 1 do
        if scene_data.SeatUids[i] ~= 0 then
          player_count = player_count + 1
        end
      end
    end
  end
  self._can_start = 2 <= player_count
  self._btn_start.interactable = self._can_start
  if self._can_start then
    UIUtil.set_text_by_id(self._txt_player_num, "Tabletop_Tutupai_Ready_Num2", tostring(player_count))
  else
    UIUtil.set_text_by_id(self._txt_player_num, "Tabletop_Tutupai_Ready_Num1")
  end
end

function M:_refresh_dealing_stage()
  if self._confirm_popup_guid then
    UIManagerInstance:close(self._confirm_popup_guid)
    self._confirm_popup_guid = nil
  end
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, false)
  self:_set_chat_state(false)
  self:_build_players()
  UIManagerInstance:open("UI/RabbitTabletop/RabbitTabletopPrepareTip", {
    on_complete = function()
      self._start_tips_delay_timer = self._uno_constant_cfg and self._uno_constant_cfg.starttipsdelay or 3
      EventCenter.Broadcast(EventID.TabletopStartGame, self._tabletop_guid)
    end
  })
end

function M:_build_players()
  self._players = {}
  local scene_data = CsTabletopGameUtil.GetTabletopGameSceneData(1, self._tabletop_guid)
  if not scene_data then
    return
  end
  local seat_count = scene_data.SeatUids.Length
  local my_uid = player_module:get_player_uid()
  local my_raw = 0
  for i = 0, seat_count - 1 do
    if scene_data.SeatUids[i] == my_uid then
      my_raw = i
      break
    end
  end
  local brief_map = {}
  local briefs = scene_data.PlayerBriefs
  if briefs then
    Logger.Log(string.format("[RabbitTabletopMainPage] PlayerBriefs count:%d", briefs.Count))
    for i = 0, briefs.Count - 1 do
      local b = briefs[i]
      Logger.Log(string.format("[RabbitTabletopMainPage] Brief[%d] Uid:%d Nickname:%s AvatarId:%d", i, b.Uid, b.Nickname, b.AvatarId))
      brief_map[b.Uid] = b
    end
  else
    Logger.Log("[RabbitTabletopMainPage] PlayerBriefs is nil")
  end
  for i = 0, seat_count - 1 do
    local uid = scene_data.SeatUids[i]
    if uid ~= 0 then
      local visual_seat = (i - my_raw) % seat_count + 1
      local brief = brief_map[uid]
      table.insert(self._players, {
        name = brief and brief.Nickname or tostring(uid),
        avatar_id = brief and brief.AvatarId or 0,
        uid = uid,
        card_count = CsTabletopGameUtil.GetHandCardCount(1, self._tabletop_guid, uid),
        seat_index = visual_seat,
        raw_seat = i,
        is_afk = false
      })
    end
  end
end

function M:_find_turn_index_by_uid(target_uid)
  for i, p in ipairs(self._players) do
    if p.uid == target_uid then
      return i - 1
    end
  end
  return 0
end

function M:_refresh_playing_stage()
  self:_set_game_state(GameState.normal)
  self:_create_indicate_items()
  local ctx = self._last_sync_ctx
  local turn_uid = ctx and ctx.deskCurrentTurnUid or 0
  self._cur_turn = self:_find_turn_index_by_uid(turn_uid)
  self:_update_players_afk()
  self:_update_player_card_counts()
  self:_refresh_all_indicates()
  self:_refresh_order_direction(ctx)
  self:_refresh_order_avatar_items(ctx)
  self:_refresh_round_text(ctx)
  self:_clear_tip_queue()
  local step = ctx and ctx.currentStep or nil
  if step then
    self:_dispatch_step(step, ctx, player_module:get_player_uid() == turn_uid)
  else
    self:_set_game_state(GameState.normal)
  end
end

function M:_refresh_round_text(ctx)
  local round = ctx and ctx.deskRound or 0
  UIUtil.set_text(self._txt_round, "当前轮次: " .. tostring(round))
end

function M:_refresh_order_direction(ctx)
  if not self._state_order then
    return
  end
  local target
  if self._cur_stage ~= Stage.playing then
    target = OrderState.none
  else
    local is_cw = ctx and ctx.isClockwise
    target = is_cw and OrderState.clockwise or OrderState.counterwise
  end
  if self._last_order_state == target then
    return
  end
  self._last_order_state = target
  self._state_order:SetState(target)
end

function M:_get_p_root(seat_index)
  if seat_index == 1 then
    return self._trans_p1_root
  elseif seat_index == 2 then
    return self._trans_p2_root
  elseif seat_index == 3 then
    return self._trans_p3_root
  elseif seat_index == 4 then
    return self._trans_p4_root
  end
  return nil
end

function M:_refresh_order_avatar_items(ctx)
  local turn_uid = ctx and ctx.deskCurrentTurnUid or 0
  self._order_avatar_items = self._order_avatar_items or {}
  local seat_to_player = {}
  if self._players then
    for _, p in ipairs(self._players) do
      seat_to_player[p.seat_index] = p
    end
  end
  for seat = 1, 4 do
    local parent = self:_get_p_root(seat)
    if not is_null(parent) then
      local item = self._order_avatar_items[seat]
      if not item then
        local go = UIUtil.load_prefab_set_parent(self._obj_item_avatar_template, parent)
        item = self:add_panel(order_avatar_cls, go.transform)
        self._order_avatar_items[seat] = item
      end
      local p = seat_to_player[seat]
      local name_state = seat == 1 and 1 or 0
      local data
      if p then
        data = {
          avatar_id = p.avatar_id,
          state = p.uid == turn_uid and AvatarItemState.playing or AvatarItemState.seated,
          name_state = name_state
        }
      else
        data = {
          avatar_id = 0,
          state = AvatarItemState.empty,
          name_state = name_state
        }
      end
      item:refresh(data)
      UIUtil.set_active(item.trans, true)
    end
  end
end

function M:_init_banner()
  self._banner_stack = {}
  self._banner_overlay_queue = {}
  self._banner_current = nil
  self._banner_timer = nil
  self._banner_visible = false
  UIUtil.set_active(self._card_animator.gameObject, false)
end

function M:_clear_banner_state()
  self._banner_stack = {}
  self._banner_overlay_queue = {}
  self._banner_current = nil
  self._banner_timer = nil
  self._banner_visible = false
  UIUtil.set_active(self._card_animator.gameObject, false)
end

function M:_banner_push_persistent(data)
  self._banner_stack[1] = data
  self:_render_banner_from_top()
end

function M:_banner_pop_persistent()
  self._banner_stack[1] = nil
  self:_render_banner_from_top()
end

function M:_banner_push_overlay(state, payload)
  local entry = {
    state = state,
    payload = payload,
    duration = OVERLAY_BANNER_DURATION[state] or 1.5
  }
  table.insert(self._banner_overlay_queue, entry)
  if not self._banner_current or self._banner_current.kind ~= "overlay" then
    self:_render_banner_from_top()
  end
end

function M:_render_banner_from_top()
  local overlay = self._banner_overlay_queue[1]
  if overlay then
    self._banner_current = {kind = "overlay", data = overlay}
    self._banner_timer = overlay.duration
    self:_show_banner_node(true)
    self:_render_banner_content(overlay.state, overlay.payload)
    return
  end
  local persistent = self._banner_stack[1]
  if persistent then
    self._banner_current = {kind = "persistent", data = persistent}
    self._banner_timer = nil
    self:_show_banner_node(true)
    local state = (persistent.chain_count or 1) >= 2 and BannerState.thunder or BannerState.add_card
    self:_render_banner_content(state, persistent)
    return
  end
  self._banner_current = nil
  self._banner_timer = nil
  self:_show_banner_node(false)
end

local function card_text_key(face_kind, sub_kind)
  return face_kind * 100 + (sub_kind or 0)
end

local CARD_NAME_TEXT_IDS = {
  [card_text_key(TutuCardFaceKind.Number, 0)] = "Tabletop_Tutupai_AddCard_Name",
  [card_text_key(TutuCardFaceKind.ColoredAction, TutuCardActionKind.Skip)] = "Tabletop_Tutupai_JumpCard_Name",
  [card_text_key(TutuCardFaceKind.ColoredAction, TutuCardActionKind.Reverse)] = "Tabletop_Tutupai_DirectionChange_Name",
  [card_text_key(TutuCardFaceKind.ColoredAction, TutuCardActionKind.Draw)] = "Tabletop_Tutupai_AddCard_Name",
  [card_text_key(TutuCardFaceKind.Wild, TutuCardWildKind.ColorChange)] = "Tabletop_Tutupai_ChangeColor_Name",
  [card_text_key(TutuCardFaceKind.Wild, TutuCardWildKind.PenaltyWheel)] = "Tabletop_Tutupai_TurningTable_Name",
  [card_text_key(TutuCardFaceKind.Wild, TutuCardWildKind.StarTide)] = "Tabletop_Tutupai_StarWave_Name"
}
local DECIDE_TEXT_IDS = {
  [BannerState.no_judge] = {
    [TutuCardWildKind.StarTide] = "Tabletop_Tutupai_StarWave_NoNeed"
  },
  [BannerState.into_judge] = {
    [TutuCardWildKind.StarTide] = "Tabletop_Tutupai_StarWave_Start",
    [TutuCardWildKind.PenaltyWheel] = "Tabletop_Tutupai_TurningTable_Start"
  },
  [BannerState.safe] = {
    [TutuCardWildKind.StarTide] = "Tabletop_Tutupai_StarWave_SafeTip"
  },
  [BannerState.star_tide] = {
    [TutuCardWildKind.StarTide] = "Tabletop_Tutupai_StarWave_FailTip",
    [TutuCardWildKind.PenaltyWheel] = "Tabletop_Tutupai_TurningTable_Over"
  },
  [BannerState.normal_play] = {
    [card_text_key(TutuCardFaceKind.ColoredAction, TutuCardActionKind.Skip)] = "Tabletop_Tutupai_Skip",
    [card_text_key(TutuCardFaceKind.ColoredAction, TutuCardActionKind.Reverse)] = "Tabletop_Tutupai_DirectionChange",
    [card_text_key(TutuCardFaceKind.Wild, TutuCardWildKind.ColorChange)] = "Tabletop_Tutupai_ColorChange"
  }
}
local STATE_DESC_FIELD = {
  [BannerState.no_judge] = "_txt_banner_no_judge",
  [BannerState.into_judge] = "_txt_banner_begin_judge",
  [BannerState.safe] = "_txt_banner_safe",
  [BannerState.star_tide] = "_txt_banner_judge",
  [BannerState.normal_play] = "_txt_banner_desc"
}

local function default_player()
  return {
    uid = 0,
    name = "",
    avatar_id = 0
  }
end

function M:_get_banner_trigger(state, data)
  if state == BannerState.add_card or state == BannerState.thunder then
    return data.players and data.players[#data.players] or data.operator or default_player()
  end
  return data.operator or default_player()
end

function M:_render_banner_card(state, data, trigger)
  if state == BannerState.add_card or state == BannerState.thunder then
    UIUtil.set_text_by_id(self._txt_banner_card, "Tabletop_Tutupai_AddCard_Who", trigger.name or "")
  elseif state == BannerState.add_card_result then
    UIUtil.set_text_by_id(self._txt_banner_card, "Tabletop_Tutupai_AddCard_Fail")
  else
    local face_kind = data.face_kind
    if not face_kind then
      return
    end
    local name_id = CARD_NAME_TEXT_IDS[card_text_key(face_kind, data.sub_kind)]
    if not name_id then
      return
    end
    UIUtil.set_text_by_id(self._txt_banner_card, "Tabletop_Tutupai_CardPlayed", UIUtil.get_text_by_id(name_id))
  end
end

function M:_render_banner_desc(state, data)
  local decide_map = DECIDE_TEXT_IDS[state]
  local field_name = STATE_DESC_FIELD[state]
  if not decide_map or not field_name then
    return
  end
  local key = state == BannerState.normal_play and card_text_key(data.face_kind or 0, data.sub_kind) or data.sub_kind
  local text_id = decide_map[key]
  if text_id then
    UIUtil.set_text_by_id(self[field_name], text_id)
  end
end

function M:_render_banner_content(state, data)
  self._state_card_decide:SetState(state)
  data = data or {}
  local trigger = self:_get_banner_trigger(state, data)
  UIUtil.set_text(self._txt_banner_name_dynamic, trigger.name or "")
  self:_render_banner_card(state, data, trigger)
  if state == BannerState.thunder then
    self:_refresh_banner_thunder_heads(data.players or {trigger})
    UIUtil.set_text(self._txt_banner_stack_num, TextMapFormatUtil.GetMultiplySign() .. tostring(data.chain_count or 1))
  else
    self:_refresh_banner_single_head(trigger)
  end
  if state == BannerState.add_card_result then
    UIUtil.set_text_by_id(self._txt_banner_add_fail, "Tabletop_Tutupai_AddCard_Over", tostring(data.n or 0))
  end
  self:_render_banner_desc(state, data)
end

function M:_refresh_banner_single_head(player)
  if self._banner_avatar_clones then
    for _, c in ipairs(self._banner_avatar_clones) do
      UIUtil.set_active(c, false)
    end
  end
  UIUtil.set_active(self._obj_avatar_head_template, true)
  if not (player and player.avatar_id) or player.avatar_id <= 0 then
    return
  end
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), player.avatar_id)
  if head_cfg then
    UIUtil.set_image(self._img_banner_head, head_cfg.respath, self:get_load_proxy())
  end
end

function M:_refresh_banner_thunder_heads(players)
  self._banner_avatar_clones = self._banner_avatar_clones or {}
  if 1 <= #players then
    UIUtil.set_active(self._obj_avatar_head_template, true)
    self:_set_avatar_image(self._img_banner_head, players[1].avatar_id)
  else
    UIUtil.set_active(self._obj_avatar_head_template, false)
  end
  for i = 2, #players do
    local idx = i - 1
    local clone = self._banner_avatar_clones[idx]
    if not clone then
      clone = UIUtil.load_prefab_set_parent(self._obj_avatar_head_template, self._trans_avatar_group)
      self._banner_avatar_clones[idx] = clone
    end
    UIUtil.set_active(clone, true)
    local img = UIUtil.find_image(clone.transform, "node/img_head")
    self:_set_avatar_image(img, players[i].avatar_id)
    local animation = UIUtil.find_animation(clone.transform)
    if i == #players then
      animation.enabled = true
      animation:Play()
    else
      animation:Stop()
      animation.enabled = false
    end
  end
  for i = math.max(1, #players), #self._banner_avatar_clones do
    UIUtil.set_active(self._banner_avatar_clones[i], false)
  end
end

function M:_set_avatar_image(img, avatar_id)
  if not (not is_null(img) and avatar_id) or avatar_id <= 0 then
    return
  end
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id)
  if head_cfg then
    UIUtil.set_image(img, head_cfg.respath, self:get_load_proxy())
  end
end

function M:_show_banner_node(visible)
  if is_null(self._card_animator) then
    return
  end
  if self._banner_visible == visible then
    return
  end
  self._banner_visible = visible
  if visible then
    UIUtil.set_active(self._card_animator.gameObject, true)
  end
  self._card_animator:ResetTrigger("in")
  self._card_animator:ResetTrigger("out")
  self._card_animator:SetTrigger(visible and "in" or "out")
end

function M:_tick_banner(deltaTime)
  if self._banner_current and self._banner_current.kind == "overlay" and self._banner_timer then
    self._banner_timer = self._banner_timer - deltaTime
    if self._banner_timer <= 0 then
      self._banner_timer = nil
      table.remove(self._banner_overlay_queue, 1)
      self._banner_current = nil
      self:_render_banner_from_top()
    end
  end
end

function M:_handle_stacked_draw_diff(ctx)
  local last = self._last_stacked_draw_count or 0
  local cur = ctx.stackedDrawCount or 0
  if last == 0 and 0 < cur then
    local step = ctx.currentStep
    local payload = step and step.Payload
    local operator = self:_make_player_brief(payload and payload.OperatorUid or ctx.deskCurrentTurnUid)
    self:_banner_push_persistent({
      kind = "add_card",
      n = cur,
      chain_count = 1,
      players = {operator}
    })
  elseif 0 < last and last < cur then
    local banner = self._banner_stack[1]
    if banner then
      banner.n = cur
      banner.chain_count = (banner.chain_count or 1) + 1
      local step = ctx.currentStep
      local payload = step and step.Payload
      local operator = self:_make_player_brief(payload and payload.OperatorUid or ctx.deskCurrentTurnUid)
      if not self:_player_in_list(banner.players, operator.uid) then
        table.insert(banner.players, operator)
      end
      if self._banner_current and self._banner_current.kind == "persistent" then
        self:_render_banner_from_top()
      end
    end
  elseif 0 < last and cur == 0 then
    self:_banner_pop_persistent()
    local step = ctx.currentStep
    local payload = step and step.Payload
    local consumer = self:_make_player_brief(payload and payload.OperatorUid or ctx.deskCurrentTurnUid)
    self:_banner_push_overlay(BannerState.add_card_result, {operator = consumer, n = last})
  end
  self._last_stacked_draw_count = cur
end

function M:_make_player_brief(uid)
  if not uid or uid == 0 then
    return {
      uid = 0,
      name = "",
      avatar_id = 0
    }
  end
  if self._players then
    for _, p in ipairs(self._players) do
      if p.uid == uid then
        return {
          uid = p.uid,
          name = p.name,
          avatar_id = p.avatar_id
        }
      end
    end
  end
  return {
    uid = uid,
    name = tostring(uid),
    avatar_id = 0
  }
end

function M:_player_in_list(list, uid)
  if not list then
    return false
  end
  for _, p in ipairs(list) do
    if p.uid == uid then
      return true
    end
  end
  return false
end

function M:_reset_screen_effect()
  if not self._state_screen then
    return
  end
  self._state_screen:SetState(ScreenEffectState.none)
end

function M:_try_trigger_screen_effect_debuff(ctx, prev)
  if not self._state_screen or not ctx then
    return
  end
  local cur_owner = ctx.starTideOwnerUid or 0
  local prev_owner = prev and prev.starTideOwnerUid or 0
  if 0 < cur_owner and prev_owner <= 0 then
    self._state_screen:SetState(ScreenEffectState.into_judge)
  end
end

function M:_set_game_state(state, can_play)
  self._cur_game_state = state
  self._btn_action_sent = false
  self._state_state:SetState(state)
  self:_stop_countdown_display()
  local ctx = self._last_sync_ctx
  local is_add_card_stack = ctx and ctx.stackedDrawCount > 0
  local turn_name = self:_get_name_by_uid(ctx and ctx.deskCurrentTurnUid or 0)
  local cfg = self._uno_constant_cfg
  if not cfg then
    return
  end
  if self._cur_stage ~= Stage.playing then
    return
  end
  can_play = can_play or false
  self._cd_slider = nil
  if can_play and state == GameState.normal then
    self._cd_slider = self._slider_play
  end
  UIUtil.set_active(self._slider_play, can_play and state == GameState.normal)
  if state == GameState.normal then
  elseif state == GameState.cant_play then
    self._cd_slider = self._slider_wait
    if not is_add_card_stack then
      local card_name = UIUtil.get_text_by_id("Tabletop_Tutupai_JumpCard_Name")
      UIUtil.set_text_by_id(self._txt_tips_cant_play, "Tabletop_Tutupai_JumpCard_BeUsed", card_name)
    else
      UIUtil.set_text_by_id(self._txt_tips_cant_play, "Tabletop_Tutupai_AddCard_BeUsed", tostring(ctx.stackedDrawCount))
    end
  elseif state == GameState.please_draw_card then
    self._cd_slider = self._slider_draw
  elseif state == GameState.change_color then
    self._cd_slider = self._slider_wait
    self._wheel_change_color:set_interactable(true)
    self._wheel_change_color:set_active(true)
  elseif state == GameState.change_color_guest then
    self._wheel_change_color:set_interactable(false)
    self._wheel_change_color:set_active(true)
    UIUtil.set_text_by_id(self._txt_tips_other, "Tabletop_Tutupai_ChangeColor_ChangeOther", turn_name)
  elseif state == GameState.wheel_star then
    self._cd_slider = self._slider_wheel_star_tide
    self:_reset_star_tide_wheel()
  elseif state == GameState.wheel_star_guest then
    self:_reset_star_tide_wheel()
    UIUtil.set_text_by_id(self._txt_tips_other, "Tabletop_Tutupai_StarWave_OtherDoing", turn_name)
  elseif state == GameState.wheel_add then
    self._cd_slider = self._slider_wheel_draw
    self:_reset_draw_wheel()
  elseif state == GameState.wheel_add_guest then
    self:_reset_draw_wheel()
    UIUtil.set_text_by_id(self._txt_tips_other, "Tabletop_Tutupai_TurningTable_Playing", turn_name)
  end
  UIUtil.set_active(self._txt_tips_add, is_add_card_stack and can_play)
end

function M:_reset_star_tide_wheel()
  self._wheel_star_tide:set_select_state(0)
  self._wheel_star_tide:hide_zone_highlight()
  self._wheel_star_tide:set_active(true)
end

function M:_reset_draw_wheel()
  self._wheel_draw:set_select_state(0)
  self._wheel_draw:hide_zone_highlight()
  self._wheel_draw:reset_all_text()
  self._wheel_draw:set_active(true)
end

function M:_on_btn_draw_click()
  if self._btn_action_sent then
    return
  end
  if self._tabletop_guid then
    self._btn_action_sent = true
    self:_stop_countdown_display()
    CsTabletopGameUtil.SendUiAction(self._tabletop_guid, TutuCardUiActionType.NoPlayableDraw)
  end
end

function M:_on_btn_wheel_star_tide_click()
  if self._btn_action_sent then
    return
  end
  if self._tabletop_guid then
    self._btn_action_sent = true
    self:_stop_countdown_display()
    CsTabletopGameUtil.SendUiAction(self._tabletop_guid, TutuCardUiActionType.StarTideJudge)
  end
end

function M:_on_btn_wheel_draw_click()
  if self._btn_action_sent then
    return
  end
  if self._tabletop_guid then
    self._btn_action_sent = true
    self:_stop_countdown_display()
    CsTabletopGameUtil.SendUiAction(self._tabletop_guid, TutuCardUiActionType.PenaltyWheelSpin)
  end
end

function M:_on_tabletop_ui_action(notify)
  if is_null(notify) then
    return
  end
  local action_type = notify.UiActionType
  Logger.Log(string.format("[RabbitTabletopMainPage] _on_tabletop_ui_action action_type:%s", tostring(action_type)))
end

function M:_on_toggle_round()
  _show_round = not _show_round
  UIUtil.set_active(self._trans_round, _show_round and self._cur_stage == Stage.playing)
  UIUtil.show_tips(_show_round and "GM: 回合数显示 开" or "GM: 回合数显示 关")
end

function M:_on_seat_down_finished()
  self._waiting_seat = false
  self._waiting_seat_timeout = nil
end

function M:_on_close_rabbit_main_ui(guid)
  if guid ~= self._tabletop_guid then
    return
  end
  if self._cur_stage == Stage.playing then
    UIUtil.show_tips_by_text_id("Tabletop_Tutupai_Other_NoPlayingOut")
  end
  if self._confirm_popup_guid then
    UIManagerInstance:close(self._confirm_popup_guid)
    self._confirm_popup_guid = nil
  end
  local window = UIManagerInstance:is_show("UI/RabbitTabletop/RabbitTabletopSettlementDialog")
  if window then
    UIManagerInstance:close(window.guid)
  end
  chat_module:close_history_chat()
  self:close_self()
end

function M:trigger_star_tide_spin()
  if not self._wait_rotate_wheel then
    return
  end
  if not self._cur_step_payload then
    return
  end
  self._wait_rotate_wheel = false
  local draw_count = self._cur_step_payload.DeltaDrawCount or 0
  local state = 0 < draw_count and rabbit_tabletop_module.star_tide_select.star_tide or rabbit_tabletop_module.star_tide_select.safe
  local cfg = self._uno_constant_cfg
  local duration = cfg and cfg:starseawait(1) or nil
  local ctx = self._last_sync_ctx
  local operator_uid = self._cur_step_payload and self._cur_step_payload.OperatorUid or ctx and ctx.deskCurrentTurnUid or 0
  local operator = self:_make_player_brief(operator_uid)
  self._wheel_star_tide:start_spin(state, function()
    self:_set_game_state(GameState.normal)
  end, duration, function()
    local delta = self._cur_step_payload and self._cur_step_payload.DeltaDrawCount or 0
    local is_hit = 0 < delta
    self:_banner_push_overlay(is_hit and BannerState.star_tide or BannerState.safe, {
      operator = operator,
      n = delta,
      face_kind = TutuCardFaceKind.Wild,
      sub_kind = TutuCardWildKind.StarTide
    })
    if is_hit and self._state_screen then
      self._state_screen:SetState(ScreenEffectState.hit)
    end
  end)
end

function M:trigger_draw_wheel_spin()
  if not self._wait_rotate_wheel then
    return
  end
  if not self._cur_step_payload then
    return
  end
  self._wait_rotate_wheel = false
  local draw_count = self._cur_step_payload.DeltaDrawCount or 0
  local cfg = self._uno_constant_cfg
  local duration = cfg and cfg:rollwait(1) or nil
  Logger.Log("[RabbitTabletopMainPage] draw wheel start_spin, DeltaDrawCount=" .. tostring(draw_count))
  local ctx = self._last_sync_ctx
  local operator_uid = self._cur_step_payload and self._cur_step_payload.OperatorUid or ctx and ctx.deskCurrentTurnUid or 0
  local operator = self:_make_player_brief(operator_uid)
  self._wheel_draw:start_spin(draw_count, function()
    self:_set_game_state(GameState.normal)
  end, duration, function()
    local delta = self._cur_step_payload and self._cur_step_payload.DeltaDrawCount or 0
    self:_banner_push_overlay(0 < delta and BannerState.star_tide or BannerState.safe, {
      operator = operator,
      n = delta,
      face_kind = TutuCardFaceKind.Wild,
      sub_kind = TutuCardWildKind.PenaltyWheel
    })
  end)
end

function M:_get_name_by_uid(uid)
  if not self._players then
    return tostring(uid)
  end
  for _, p in ipairs(self._players) do
    if p.uid == uid then
      return p.name
    end
  end
  return tostring(uid)
end

function M:_on_play_card(event)
  local card_id = event and event.PlayedCardId or 0
  if card_id <= 0 then
    return
  end
  local face_kind = card_id >> TutuCardBitShift.Face & 255
  if face_kind ~= TutuCardFaceKind.ColoredAction then
    return
  end
  local sub_kind = card_id >> TutuCardBitShift.Action & 255
  if sub_kind ~= TutuCardActionKind.Skip and sub_kind ~= TutuCardActionKind.Reverse then
    return
  end
  self:_banner_push_overlay(BannerState.normal_play, {
    operator = self:_make_player_brief(event.OperatorUid or 0),
    face_kind = face_kind,
    sub_kind = sub_kind
  })
end

function M:_queue_tip(path, extra)
  table.insert(self._tip_queue, {path = path, extra = extra})
end

function M:_queue_and_play_start_tips()
  local cfg = self._uno_constant_cfg
  if not cfg then
    return
  end
  local ctx = self._last_sync_ctx
  local turn_uid = ctx and ctx.deskCurrentTurnUid or 0
  self:_queue_tip("UI/RabbitTabletop/RabbitTabletopStartTip", {
    tips = UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Start"),
    duration = cfg.bigtips
  })
  local first_name = self:_get_name_by_uid(turn_uid)
  self:_queue_tip("UI/RabbitTabletop/RabbitTabletopStartTip", {
    tips = UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_StartFrom", first_name),
    duration = cfg.bigtips
  })
  self:_play_tip_queue()
end

function M:_play_tip_queue()
  if self._tip_showing or self._tip_wait_timer then
    return
  end
  self._tip_wait_timer = nil
  if #self._tip_queue == 0 then
    return
  end
  self._tip_showing = true
  self:_play_next_tip()
end

function M:_play_next_tip()
  if #self._tip_queue == 0 then
    self._tip_showing = false
    return
  end
  local tip = table.remove(self._tip_queue, 1)
  local extra = tip.extra or {}
  
  function extra.on_close()
    if not (not is_null(self.trans) and self.is_active) or self._tip_queue == nil then
      return
    end
    self._current_tip_guid = nil
    if #self._tip_queue > 0 then
      self._tip_wait_timer = 0.5
    else
      self._tip_showing = false
    end
  end
  
  local guid = UIManagerInstance:open(tip.path, extra)
  self._current_tip_guid = guid
end

function M:_clear_tip_queue()
  self._tip_queue = {}
  self._tip_showing = false
  self._tip_wait_timer = nil
  self._start_tips_delay_timer = nil
  if self._current_tip_guid then
    UIManagerInstance:close(self._current_tip_guid)
    self._current_tip_guid = nil
  end
end

function M:_refresh_end_stage()
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, true)
  UIUtil.set_active(self._btn_close_online, false)
  self:_stop_countdown_display()
  self:_set_chat_state(false)
  UIUtil.set_active(self._btn_open_input, false)
  self:_refresh_emoji_list()
  self:_clear_banner_state()
  self:_clear_chat_bubbles()
  self:_hide_indicate_items()
  self:_reset_screen_effect()
  UIUtil.set_active(self._slider_play, false)
  local winner_name = self:_get_name_by_uid(self._winner_uid or 0)
  UIManagerInstance:open("UI/RabbitTabletop/RabbitTabletopWinerTip", {
    winner_name = UIUtil.get_text_by_id("Tabletop_Tutupai_End_Name", winner_name)
  })
end

function M:_refresh_emoji_list()
  local is_winner = self._winner_uid == player_module:get_player_uid()
  local emoji_list = is_winner and self._emoji_list or {}
  rabbit_tabletop_module:generate_and_refresh_items(self, self._emoji_pool, emoji_list, self._obj_emoji_tab, self._trans_emoji_parent, self._emoji_cls, function(item, data)
    item:refresh(data)
  end)
  if not is_winner then
    local reaction_id = self._uno_constant_cfg.otherreact
    local reaction_data = ExcelDataUtil.get_value(typeof(BReactionCfg), reaction_id)
    if not_null(reaction_data) then
      local atl_tag = reaction_data.hostatltagname
      if string.is_valid(atl_tag) then
        Logger.Log("[RabbitTabletopMainPage] broadcast settle animation, atl_tag=" .. atl_tag)
        EventCenter.Broadcast(EventID.TabletopSettleAnimation, atl_tag)
      end
    end
    UIUtil.set_active(self._obj_bottom_settlement, false)
  end
end

function M:_open_settlement()
  EventCenter.Broadcast(EventID.TabletopSettleAnimationEnd)
  UIManagerInstance:open("UI/RabbitTabletop/RabbitTabletopSettlementDialog", self._settle_data)
end

function M:_set_chat_state(is_open)
  self._is_chat_open = is_open
  self._state_chat:SetState(is_open and ChatState.open or ChatState.close)
  if not self._chat_input_field_panel then
    return
  end
  if is_open then
    self._chat_input_field_panel:show(-1)
    if self._cur_stage == Stage.ready then
      self:_set_camera_control(false)
    end
  else
    self._chat_input_field_panel:hide()
    if self._cur_stage == Stage.ready then
      self:_set_camera_control(true)
    else
      InputManagerIns:set_mouse_active(true)
    end
    chat_module:close_history_chat()
  end
end

function M:_toggle_chat()
  self:_set_chat_state(not self._is_chat_open)
end

function M:_on_btn_open_input_click()
  self:_toggle_chat()
end

function M:_on_btn_close_chat_area_click()
  if CsNativeKeyboardManagerUtil.IsKeyboardActive() then
    CsNativeKeyboardManagerUtil.HideKeyboard()
    return
  end
  self:_set_chat_state(false)
end

function M:_on_btn_start_click()
  if not self._can_start or self._is_start_game then
    return
  end
  if self._tabletop_guid ~= nil then
    self._is_start_game = true
    CsTabletopGameUtil.TrySendStartMatch(self._tabletop_guid, function(is_success)
      if not is_success then
        self._is_start_game = false
      end
    end)
  end
end

function M:_on_btn_rule_click()
  UIManagerInstance:open("UI/RabbitTabletop/RabbitTabletopIntroDialog", {game_id = 1})
end

function M:_on_btn_close_online_click()
  if self._waiting_seat then
    return
  end
  if self._cur_stage == Stage.ready then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("Tabletop_Tutupai_Ready_Warn2"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Confirm"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Cancel"), UIUtil.get_text_by_id("Tabletop_Tutupai_Ready_Warn1"))
    popup:set_callbacks(function()
      self._confirm_popup_guid = nil
      self:close_self()
    end, function()
      self._confirm_popup_guid = nil
    end)
    self._confirm_popup_guid = popup:show()
  elseif self._cur_stage == Stage.playing then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_HintWord"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Confirm"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Cancel"))
    popup:set_callbacks(function()
      self._confirm_popup_guid = nil
      self:close_self()
    end, function()
      self._confirm_popup_guid = nil
    end)
    self._confirm_popup_guid = popup:show()
  end
end

function M:_on_chat_notify(chat_data)
  if not chat_data then
    return
  end
  if self._is_chat_open and chat_data.from_uid == player_module:get_player_uid() and chat_module:chat_is_emoji(chat_data) and not UIManagerInstance:is_show("UI/ChatMain/HistoryChatDialog") then
    self:_set_chat_state(false)
  end
  if self._cur_stage ~= Stage.playing and self._cur_stage ~= Stage.dealing then
    return
  end
  if not chat_module:chat_is_emoji(chat_data) and not string.is_valid(chat_data.content) then
    return
  end
  local seat_idx = self:_get_seat_by_uid(chat_data.from_uid)
  if not seat_idx then
    return
  end
  local bubble = self._chat_bubbles[seat_idx]
  if bubble then
    bubble:add_chat(chat_data)
  end
end

function M:_get_seat_by_uid(uid)
  if not self._players then
    return nil
  end
  for i, p in ipairs(self._players) do
    if p.uid == uid then
      return p.seat_index
    end
  end
  return nil
end

function M:_clear_chat_bubbles()
  if not self._chat_bubbles then
    return
  end
  for _, bubble in pairs(self._chat_bubbles) do
    bubble:clear()
  end
end

function M:_create_indicate_items()
  self:_hide_indicate_items()
  if not self._players then
    return
  end
  for _, p in ipairs(self._players) do
    local seat = self._seat_map[p.seat_index]
    if seat and not self._indicate_items[p.seat_index] then
      local go = UIUtil.load_prefab_set_parent(self._trans_turn_indicate_group.gameObject, seat.indicate_root)
      self._indicate_items[p.seat_index] = self:add_panel(indicate_cls, go.transform)
    end
  end
  self:_update_players_afk()
  self:_refresh_all_indicates()
  self:_adjust_bottom_indicate_position()
end

function M:_adjust_bottom_indicate_position()
  local aspect = Screen.width / Screen.height
  local y = BASE_INDICATE_Y
  if aspect < BASE_ASPECT then
    local t = math.min(1, (BASE_ASPECT - aspect) / (BASE_ASPECT - MIN_ASPECT))
    y = BASE_INDICATE_Y + (MAX_INDICATE_Y - BASE_INDICATE_Y) * t
  end
  local pos = self._trans_bottom_indicate_root.anchoredPosition
  self._trans_bottom_indicate_root.anchoredPosition = Vector2(pos.x, y)
end

function M:_update_players_afk()
  if not self._players then
    return
  end
  local scene_data = CsTabletopGameUtil.GetTabletopGameSceneData(1, self._tabletop_guid)
  if not scene_data then
    return
  end
  for _, p in ipairs(self._players) do
    p.is_afk = scene_data.SeatUids[p.raw_seat] == 0
  end
end

function M:_is_player_left(uid)
  if not self._players then
    return false
  end
  for _, p in ipairs(self._players) do
    if p.uid == uid then
      return p.is_afk
    end
  end
  return true
end

function M:_is_turn_player_afk()
  local ctx = self._last_sync_ctx
  if not ctx or not self._players then
    return false
  end
  local turn_uid = ctx.deskCurrentTurnUid
  for _, p in ipairs(self._players) do
    if p.uid == turn_uid then
      return p.is_afk
    end
  end
  return false
end

function M:_refresh_all_indicates()
  if not self._players then
    return
  end
  local turn_uid = self._last_sync_ctx and self._last_sync_ctx.deskCurrentTurnUid or 0
  for _, p in ipairs(self._players) do
    local item = self._indicate_items[p.seat_index]
    if item then
      local is_active = p.uid == turn_uid
      UIUtil.set_active(item.trans, is_active)
      if is_active then
        item:refresh({
          name = p.name,
          card_count = p.card_count,
          is_afk = p.is_afk,
          turn_index = (p.seat_index - 2) % 4
        })
      end
    end
  end
end

function M:_hide_indicate_items()
  for _, item in pairs(self._indicate_items) do
    if item and item.trans then
      UIUtil.set_active(item.trans, false)
    end
  end
end

function M:_start_countdown_display(duration_sec)
  if not duration_sec or duration_sec <= 0 then
    return
  end
  self._cd_timer = duration_sec
  self._cd_total = duration_sec
  if self._cd_slider then
    self._cd_slider.value = self._cd_slider == self._slider_play and 1 or 0
  end
end

function M:_stop_countdown_display()
  self._cd_timer = nil
  self._cd_slider = nil
end

function M:_tick_countdown_display(deltaTime)
  if not self._cd_timer then
    return
  end
  self._cd_timer = self._cd_timer - deltaTime
  if self._cd_slider then
    local progress = 1 - self._cd_timer / self._cd_total
    progress = math.min(progress, 1)
    self._cd_slider.value = self._cd_slider == self._slider_play and 1 - progress or progress
  end
  if self._cd_timer <= 0 then
    self:_stop_countdown_display()
  end
end

return M
