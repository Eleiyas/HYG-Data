chat_module = chat_module or {}

function chat_module:set_chat_emoji(img, emoji_id, load_proxy)
  if is_null(img) or emoji_id == nil or emoji_id <= 0 then
    return
  end
  local cfg = chat_module:get_def_emoji_cfg_by_id(emoji_id)
  if cfg then
    UIUtil.set_image(img, cfg.icon, load_proxy)
  end
end

function chat_module:show_player_arrived_tips(player_name)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.player_arrived_tip, player_name)
end

function chat_module:show_player_leave_tips(player_name)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.player_leave_tip, player_name)
end

return chat_module
