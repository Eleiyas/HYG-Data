chat_module = chat_module or {}
chat_module.MaxPullChatInfoCount = 125
chat_module.npc_chat_data_max_num = 25
chat_module.npc_chat_send_cd = 5
chat_module.npc_chat_time_out = 50
chat_module.chat_type = {
  input_text = 1,
  emoji_id = 2,
  quick_text_id = 3,
  player_enter_world = 4,
  player_leave_world = 5,
  public_start_input = 6,
  public_end_input = 7,
  npc_text = 8
}
chat_module.chat_friend_max_num = 15
chat_module.public_chat_value = 100000000
chat_module.chat_red_max_num = 99
chat_module.chat_data_max_num = 100
chat_module.chat_input_field_panel_cls_name = "UI/Chat/ChatInputFieldPanel"
chat_module.def_chat_txt_show_type = {
  all = 0,
  one = 1,
  multi = 3
}
return chat_module
