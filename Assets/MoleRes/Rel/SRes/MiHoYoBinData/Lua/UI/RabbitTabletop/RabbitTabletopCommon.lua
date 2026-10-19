rabbit_tabletop_module = rabbit_tabletop_module or {}
rabbit_tabletop_module.stage = {
  ready = 0,
  playing = 1,
  settling = 2,
  dealing = 3,
  ending = 4
}
rabbit_tabletop_module.game_state = {
  normal = 0,
  cant_play = 1,
  please_draw_card = 2,
  change_color = 3,
  wheel_star = 4,
  wheel_add = 5,
  change_color_guest = 6,
  wheel_star_guest = 7,
  wheel_add_guest = 8,
  normal_no_timer = 9
}
rabbit_tabletop_module.chat_state = {close = 0, open = 1}
rabbit_tabletop_module.star_tide_select = {
  none = 0,
  safe = 1,
  star_tide = 2
}
return rabbit_tabletop_module or {}
