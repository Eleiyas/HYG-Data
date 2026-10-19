local M = G.Class("PlayerIntimacyBestFriendInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/PlayerIntimacyBestFriendInfo"
  self.config.type = EUIType.Dialog
  friend_level_module.interact_record_view.init_panel_state(self)
  self._use_switch_content_anim = true
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  friend_level_module.interact_record_view.on_create_panel(self)
end

function M:on_enable()
  base.on_enable(self)
  friend_level_module.interact_record_view.on_enable_panel(self)
end

function M:on_disable()
  base.on_disable(self)
  friend_level_module.interact_record_view.on_disable_panel(self)
  if UIIdleDetectManagerIns then
    UIIdleDetectManagerIns:try_show_moonlet()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.AnimationEventTrigger, function(event_name)
    friend_level_module.interact_record_view.on_switch_anim_event(self, event_name)
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  friend_level_module.interact_record_view.bind_close_btn_with_out_anim(self)
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  self:bind_callback(self._btn_page_left, pack(self, M._on_page_left_click))
  self:bind_callback(self._btn_page_right, pack(self, M._on_page_right_click))
end

function M:_on_btn_info_click()
  common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.friend_intro)
end

function M:refresh_view(friend_data)
  self._cur_friend_data = friend_data
  self._summary_unlocked = friend_level_module:check_summary_unlocked(friend_data)
  UIUtil.set_active(self._btn_page_left, self._summary_unlocked)
  UIUtil.set_active(self._btn_page_right, self._summary_unlocked)
  friend_level_module.interact_record_view.refresh_record_items(self, true)
  self:refresh_friend_info()
  self:refresh_self_info()
end

function M:refresh_self_info()
  local nick_name = player_module:get_player_name()
  player_module:set_player_icon(self._img_player_head, self:get_load_proxy())
  UIUtil.set_text(self._txt_name_player, nick_name)
end

function M:refresh_friend_info()
  local friend_name = self._cur_friend_data.nick_name
  local became_bestie_time = self._cur_friend_data:get_became_bestie_time() or 0
  local time_str = os.date("%Y/%m/%d", math.floor(became_bestie_time))
  self:_set_head_icon()
  UIUtil.set_text(self._txt_friend_name, friend_name)
  UIUtil.set_text(self._txt_time, UIUtil.get_text_by_id("BEST_FRIEND_FORM_TIME") .. ":" .. time_str)
end

function M:_set_head_icon()
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), self._cur_friend_data.avatar_id)
  if head_cfg then
    UIUtil.set_image(self._img_friend_head, head_cfg.respath, self:get_load_proxy())
  end
end

function M:_on_page_left_click()
  friend_level_module.interact_record_view.on_page_left_click(self)
end

function M:_on_page_right_click()
  friend_level_module.interact_record_view.on_page_right_click(self)
end

return M
