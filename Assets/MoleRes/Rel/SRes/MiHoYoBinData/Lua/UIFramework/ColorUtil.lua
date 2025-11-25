local ColorUtil = {}
ColorUtil.C = {
  transparent = "#FFFFFF00",
  white = "#FFFFFF",
  black = "#000000FF",
  task_lv2_0_unchecked = "#605245FF",
  task_lv4_text = "#4F6E71",
  take_int_text_black = "#323232FF",
  take_int_text_and_box_gray = "#8F8271DC",
  take_int_box_black = "#373737FF",
  tool_table_material_text_red = "#eb5672",
  tool_table_material_text_green = "#A8A8A8FF",
  main_task = "#FDE84BFF",
  shop_item_sell_out_img = "#7A7A7AFF",
  shop_item_sell_out_price = "#B0B0B0FF",
  shop_item_price_def = "#9ea77bFF",
  achieve_sub_item_un_get = "#646464FF",
  day_task_is_get = "#B4B4B4FF",
  day_task_des_def = "#E3E2DEFF",
  day_task_des_is_get = "#E3E2DEC8",
  day_task_un_get_bg = "#A6BE91FF",
  day_task_get_bg = "#7F9071FF",
  day_task_des_can_get = "#222222FF",
  tips_info_bg_def = "#1D2D32FF",
  tips_info_txt_def = "#FAF5B1FF",
  tips_info_bg_star_core = "#EAE3DBFF",
  tips_info_txt_star_core = "#535353FF",
  item_quality_1 = "#C7CAB4FF",
  item_quality_2 = "#83D083FF",
  item_quality_3 = "#95BFCCFF",
  item_quality_4 = "#A680B1FF",
  furnitureDetailGreen = "#1B6E2AFF",
  gift_pack_green = "#C8D4AED4",
  gift_pack_blue = "#8ECCCBFF",
  gift_pack_purple = "#B9AECBFF",
  letter_over_flow_warning = "#EADC68FF",
  letter_over_flow_error = "#F59880FF",
  gm_btn_local = "#65A9B2FF",
  gm_btn_server = "#007A8BFF",
  main_page_chat_item_bg_color_public = "#FFF9E3BB",
  main_page_chat_item_bg_color_friend = "#DEFECBC8",
  main_page_chat_item_txt_color_friend = "#484A38FF",
  main_page_chat_item_txt_color_public = "#663C22FF",
  friend_online_color = "#79AF57",
  friend_offline_color = "#C1C5AEFF",
  npc_contact_book_detail_item_bg_common_main = "#68A285FF",
  npc_contact_book_detail_item_bg_common_side = "#9B9A40FF",
  npc_contact_book_detail_item_bg_common_other = "#A28339FF",
  npc_contact_book_detail_item_bg_emphasize = "#433B30FF",
  npc_contact_book_npc_item_bg_main = "#A6D7C5FF",
  npc_contact_book_npc_item_bg_side = "#EEE646FF",
  npc_contact_book_npc_item_bg_other = "#F5C655FF",
  npc_contact_book_npc_item_icon_main = "#82C5AC96",
  npc_contact_book_npc_item_icon_side = "#D6CF4396",
  npc_contact_book_npc_item_icon_other = "#E0B44B96",
  chat_bubble_text_me = "#f8f4dc",
  chat_bubble_text_other = "#584626"
}
local color = {}

local function get_color(str)
  if color[str] then
    return color[str]
  end
  color[str] = CsUIUtil.ParseColor(str)
  return color[str]
end

local function color_text(str, text)
  return string.format("<color=%s>%s</color>", str, text)
end

ColorUtil.get_color = get_color
ColorUtil.color_text = color_text
return ColorUtil
