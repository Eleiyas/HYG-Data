hair_dyeing_module = hair_dyeing_module or {}
hair_dyeing_module.dye_mode = {flower = 1, dye = 2}
hair_dyeing_module.dye_part = {global = 1, region = 2}
hair_dyeing_module.dye_type = {pure = 1, gradient = 2}
hair_dyeing_module.result_type = {
  pure_color = 1,
  gradient_color = 2,
  rainbow_inspiration = 3,
  inspiration_active = 4,
  inspiration_paid = 5,
  fail = 6
}
hair_dyeing_module.exchange_inspiration_type = {
  active = 1,
  paid = 2,
  rainbow = 3
}
hair_dyeing_module.max_flower_select = 2

function hair_dyeing_module:calc_worn_state(owned, selected)
  return (owned and 1 or 0) + (selected and 2 or 0)
end

hair_dyeing_module.currency = {
  dye_agent = 200021,
  inspiration_active = 200023,
  inspiration_paid = 200024,
  rainbow_inspiration = 200022
}
hair_dyeing_module.twinkle_interval = 0.3
hair_dyeing_module.twinkle_times = 2
hair_dyeing_module.rotate_speed = 0.1
hair_dyeing_module.cam_state = {
  mode_select = "HairDyeingModeSelect",
  flower = "HairDyeingFlower",
  dye = "HairDyeingDye",
  exchange = "HairDyeingExchange"
}
hair_dyeing_module.tab_cfg_id = {
  mode_select = 1,
  flower = 2,
  dye = 3,
  exchange = 4
}
hair_dyeing_module.ui_prefab_path = {
  mode_select = "UI/HairDyeing/HairDyeingSelectPanel",
  flower = "UI/HairDyeing/HairDyeingFlowerPanel",
  dye = "UI/HairDyeing/HairDyeingMoneyPanel",
  fail_result = "UI/HairDyeing/HairDyeingFailDialog",
  exchange = "UI/HairDyeing/HairDyeingExchangePage"
}
return hair_dyeing_module
