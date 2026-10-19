npc_module = npc_module or {}
npc_module.return_gift_type = {
  none = 0,
  memory = 1,
  wanted = 2,
  gift_id_type = 3,
  gift_id = 4,
  missive_gift = 6,
  favor_reach = 7,
  first_gift = 8
}
npc_module.memory_type = {last = 1}
npc_module.give_gift_type = {talk = 0, express = 1}
npc_module.give_step_type = {
  player_give_start = 1,
  npc_get_start = 2,
  npc_get_end = 3,
  npc_give_start = 4,
  player_get_start = 5,
  player_get_end = 6
}
npc_module.npc_cloth_tog_types = {
  none = -1,
  self = 0,
  npc = 1
}
return npc_module or {}
