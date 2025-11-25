item_module = item_module or {}

function item_module:add_event()
  item_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowGetItemTip] = pack(self, self._add_item)
  self._events[EventID.LuaChangePacket] = pack(self, self._on_item_change_end)
  self._events[EventID.OpenMakeItemFinishInfo] = pack(self, self._open_make_item_finish_info)
  self._events[EventID.OnDailyObtainItemNotify] = pack(self, self._on_daily_obtain_item_notify)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function item_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function item_module:_add_handle(obj, handle)
  if self._tbl_item_handle == nil then
    self._tbl_item_handle = {}
  end
  if not is_null(obj) then
    self._tbl_item_handle[obj] = handle
  end
end

function item_module:remove_handle(obj)
  if not is_null(obj) and self._tbl_item_handle and self._tbl_item_handle[obj] then
    CsUIUtil.DismissResource(self._tbl_item_handle[obj])
    self._tbl_item_handle[obj] = nil
  end
end

function item_module:remove_all_handle()
  if self._tbl_item_handle then
    for _, v in pairs(self._tbl_item_handle) do
      CsUIUtil.DismissResource(v)
    end
    self._tbl_item_handle = nil
  end
end

function item_module:get_item_name_by_id(item_id, server_data)
  local ret_name = ""
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg then
    ret_name = cfg.name
    if not is_null(server_data) then
      local food_info = server_data.FoodExtension
      if not is_null(food_info) then
        local food_str = item_module:get_item_food_str(server_data)
        return food_str .. ret_name
      end
      local npc_house_info = server_data.NpcHouseAnchor
      if not is_null(npc_house_info) then
        local npc_id = npc_house_info.NpcConfigId
        local npc_cfg = LocalDataUtil.get_value(typeof(CS.BNpcCfg), npc_id)
        local npc_name = ""
        if npc_cfg then
          npc_name = npc_cfg.name .. "的"
        end
        return npc_name .. ret_name
      end
    end
  end
  return ret_name
end

function item_module:get_item_food_str(server_data)
  if is_null(server_data) then
    return ""
  end
  local food = server_data.FoodExtension
  if is_null(food) then
    return ""
  end
  local bit = food.FlavorBitMask
  local food_str = ""
  if item_module:food_flavor_is_normal(food) then
  elseif item_module:food_flavor_is_sweet(food) then
    food_str = UIUtil.get_text_by_id("Food_Sweet")
  elseif item_module:food_flavor_is_salty(food) then
    food_str = UIUtil.get_text_by_id("Food_Salty")
  elseif item_module:food_flavor_is_spicy(food) then
    food_str = UIUtil.get_text_by_id("Food_Spicy")
  elseif item_module:food_flavor_is_tasteless(food) then
    food_str = UIUtil.get_text_by_id("Food_Tasteless")
  elseif item_module:food_flavor_is_wrong_taste(food) then
    food_str = UIUtil.get_text_by_id("Food_Weird")
  end
  if item_module:food_flavor_is_burnt(food) then
    food_str = food_str .. UIUtil.get_text_by_id("Food_OverCooked")
  end
  return food_str
end

function item_module:food_flavor_is_normal(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.normal) == 1
end

function item_module:food_flavor_is_sweet(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.sweet) == 1
end

function item_module:food_flavor_is_salty(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.salty) == 1
end

function item_module:food_flavor_is_spicy(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.spicy) == 1
end

function item_module:food_flavor_is_tasteless(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.tasteless) == 1
end

function item_module:food_flavor_is_wrong_taste(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.wrong_taste) == 1
end

function item_module:food_flavor_is_burnt(food)
  if is_null(food) then
    return false
  end
  local bit = food.FlavorBitMask
  return math.get_bit(bit, item_module.food_flavor_bit.burnt) == 1
end

function item_module:get_item_des_by_id(item_id)
  local item_cfg = item_module:get_cfg_by_id(item_id)
  if is_null(item_cfg) then
    return ""
  end
  return item_cfg.itemdescribe or ""
end

function item_module:asy_load_item_prefab_3d(item_id, load_action)
  local asset_path = item_module:get_item_model_path(item_id)
  if not string.is_valid(asset_path) then
    return
  end
  CsUIUtil.LoadPrefabAsync(asset_path, function(go, handle)
    item_module:_add_handle(go, handle)
    if load_action then
      load_action(go)
    end
  end)
end

function item_module:get_item_model_path(item_id)
  local asset_path
  if item_module:item_is_recipe(item_id) then
    asset_path = CS.BEntityCfg.GetDisplayAssetPath(item_id)
  else
    local id_cfg = item_module:get_id_cfg_by_id(item_id)
    if not is_null(id_cfg) then
      if is_null(id_cfg.entityCfg) then
        asset_path = ""
      else
        asset_path = id_cfg.entityCfg.assetpath
      end
    end
  end
  if not string.is_valid(asset_path) or string.find(asset_path, "#N/A") or asset_path[#asset_path] == "/" then
    return ""
  end
  return asset_path
end

function item_module:_filter_special_type(data)
  local item_cfg = data.cfg
  if string.is_valid(item_cfg.getdescribe) then
    UIManagerInstance:open("UI/MiTai/MiTaiItemTip", {data = data})
    return false
  end
  return false
end

function item_module:filter_item_tip_by_data(data)
  if data.IsCoin and (data.id == back_bag_module.coin_type.original_recharge or data.id == back_bag_module.coin_type.secondary_recharge) then
    return true
  end
  if data.ConFigID == 200100 then
    return true
  end
  return false
end

function item_module:show_get_item_tip(item_data)
  if not CsCreatePlayerManagerUtil.IsNull() and CsCreatePlayerManagerUtil.creatingPlayer then
    return
  end
  if RuntimeWorldEditor.Current.IsEditing then
    return
  end
  if is_null(item_data) then
    return
  end
  if item_module:_filter_special_type(item_data) then
    return
  end
  if item_module:filter_item_tip_by_data(item_data) then
    return
  end
  if item_module:is_road(item_data.ConFigID) then
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.get_item_tip, item_data)
end

function item_module:_add_item(item_data)
  if self._item_tips_show_num < 10 then
    self._item_tips_show_num = self._item_tips_show_num + 1
    item_module:show_get_item_tip(item_data)
  end
  if item_data == nil or item_data.IsCoin then
    return
  end
  if item_module:is_road(item_data.ConFigID) then
    return
  end
  if item_module:item_is_recipe(item_data.ConFigID) then
    local recipe_cfg = recipe_module:get_recipe_cfg_by_id(item_data.ConFigID)
    if recipe_cfg ~= nil and recipe_cfg.autolearm == 1 then
      if not recipe_module:recipe_is_learn(item_data.ConFigID) then
        item_module:add_auto_eat_item(item_data)
        item_module:auto_use_recipe()
      elseif recipe_module:recipe_is_learn(item_data.ConFigID) then
        UIUtil.show_tips_by_text_id("Item_BookIsLearn")
      end
    end
  elseif item_data.ConFigID == 22005 then
    item_module:add_auto_eat_item(item_data)
    item_module:auto_use_recipe()
  elseif item_module:is_expansion_ticket(0, item_data.idCfg) or item_module:is_function_unlock(0, item_data.idCfg) then
    if self._auto_learn_secretly then
      item_module:set_auto_learn_secretly(false)
      item_module:add_auto_eat_item(item_data)
      item_module:auto_use_recipe()
    end
  elseif item_module:is_flyer(0, item_data.idCfg) then
    item_module:add_leaflet_data(item_data)
  elseif item_module:is_auto_use(0, item_data.idCfg) then
    item_module:add_auto_eat_item(item_data)
    item_module:auto_use_recipe()
  end
end

function item_module:_on_item_change_end()
  self._item_tips_show_num = 0
end

function item_module:_on_daily_obtain_item_notify()
  function self._first_gain_biota_fun()
    item_module:show_first_gain_biota_perform()
  end
end

function item_module:check_first_gain_biota_fun()
  if self._first_gain_biota_fun ~= nil then
    if back_bag_module:get_packet_data():GetShowPerformanceItemId() <= 0 then
      self._first_gain_biota_fun = nil
      return false
    end
    self._first_gain_biota_fun()
    self._first_gain_biota_fun = nil
    return true
  end
  return false
end

function item_module:show_first_gain_biota_perform()
  InputManagerIns:lock_input(input_lock_from.Common)
  local dis = GameplayUtility.Camera.MainCamera.transform.position - player_module:get_player_entity().Position
  dis.y = 0
  local rotation = Quaternion.LookRotation(dis)
  CommandUtil.AllocateForceLerpToTargetCmd(player_module:get_player_entity().guid, false, CmdPositionOffsetType.WorldPosition, Vector3.zero, true, CmdRotationType.WorldRotation, rotation, player_module:get_player_entity().guid, 0.3)
  local item_id = back_bag_module:get_packet_data():GetShowPerformanceItemId()
  if item_module:is_insect(item_id) then
    InputManagerIns:unlock_input(input_lock_from.Common)
    CsPerformanceManagerUtil.ShowPerformance(3000040001)
    return
  end
  player_module:get_player_entity():ShowItemInQueue(true, item_id, player_module:get_player_entity().guid, function()
    GameplayUtility.Camera.SetUIActive("ShowOff", function()
      InputManagerIns:unlock_input(input_lock_from.Common)
      CsPerformanceManagerUtil.ShowPerformance(3000040001, function()
        GameplayUtility.Camera.ExitUI("ShowOff")
        player_module:get_player_entity():ShowItem(false, 0)
      end)
    end)
  end)
end

function item_module:add_leaflet_data(item_data)
  local is_open = false
  if self._tbl_leaflet_data == nil then
    self._tbl_leaflet_data = {}
    is_open = true
  end
  table.insert(self._tbl_leaflet_data, item_data)
  if is_open then
    item_module:open_leaflet_page()
  end
end

function item_module:get_leaflet_data()
  if self._tbl_leaflet_data == nil or #self._tbl_leaflet_data <= 0 then
    return nil
  end
  local ret_data = self._tbl_leaflet_data[1]
  table.remove(self._tbl_leaflet_data, 1)
  return ret_data
end

function item_module:close_leaflet_data()
  self._tbl_leaflet_data = nil
end

function item_module:add_auto_eat_item(item_data)
  if self._auto_eat_item == nil then
    self._auto_eat_item = {}
  end
  table.insert(self._auto_eat_item, item_data)
end

function item_module:get_item_by_make_id(make_id)
  if make_id and 0 < make_id and not is_null(back_bag_module:get_packet_data()) then
    return back_bag_module:get_packet_data():GetItemByMakeGUID(make_id)
  end
  return nil
end

function item_module:get_item_by_guid(guid)
  if guid and 0 < guid and not is_null(back_bag_module:get_packet_data()) then
    return back_bag_module:get_packet_data():GetItemByGUID(guid)
  end
  return nil
end

function item_module:get_item_by_cfg_id(cfg_id)
  if cfg_id and 0 < cfg_id and not is_null(back_bag_module:get_packet_data()) then
    return back_bag_module:get_packet_data():GetItemByCfgId(cfg_id)
  end
  return nil
end

function item_module:get_item_durable_by_make_id(make_id)
  local item_data = item_module:get_item_by_make_id(make_id)
  if is_null(item_data) then
    return -1
  end
  if item_data.cfg.bagtype == ItemBagType.BagTypeTool.value__ then
    return item_data.Durable
  end
  return -1
end

function item_module:get_item_num_by_cfg_id(cfg_id)
  local item_num = 0
  if cfg_id and 0 < cfg_id then
    item_num = back_bag_module:get_item_num(cfg_id, 0)
  end
  return item_num
end

function item_module:get_item_total_num_by_cfg_id(cfg_id)
  local packet_num = back_bag_module:get_item_num(cfg_id)
  local depot_num = warehouse_module:get_warehouse_item_num(cfg_id)
  return packet_num + depot_num
end

function item_module:get_all_item_by_cfg_id(cfg_id)
  local ret_tbl = {}
  if cfg_id and 0 < cfg_id then
    ret_tbl = list_to_table(back_bag_module:get_packet_data():GetItemsByCfgId(cfg_id))
  end
  return ret_tbl
end

function item_module:get_has_tool_data()
  return list_to_table(back_bag_module:get_packet_data():GetItemIdsByTag(EntityTagTags.Tags.chandheldtool_handheldtool_tool, true))
end

function item_module:tool_is_can_repair(tool_id)
  local is_can_repair = false
  local tool_data = item_module:get_all_item_by_cfg_id(tool_id)[1]
  if not is_null(tool_data) then
    local tool_cfg = item_module:get_tool_cfg_by_id(tool_id)
    is_can_repair = tool_data.Durable < tool_cfg.times
  end
  return is_can_repair
end

function item_module:get_make_id_by_cfg_id(cfg_id)
  local data = item_module:get_all_item_by_cfg_id(cfg_id)[1]
  if not is_null(data) then
    return data.MakeGUID
  end
  return 0
end

function item_module:get_guid_by_cfg_id(cfg_id)
  local data = item_module:get_all_item_by_cfg_id(cfg_id)[1]
  if not is_null(data) then
    return data.GUID
  end
  return 0
end

function item_module:get_item_bag_type_by_id(cfg_id)
  if cfg_id and 0 < cfg_id then
    local cfg = item_module:get_cfg_by_id(cfg_id)
    if cfg then
      return cfg.bagtype
    end
  end
  Logger.LogError("物品未配置bagType item_id = " .. cfg_id)
  return ItemBagType.BagTypeNone
end

function item_module:get_item_quality_by_id(item_id)
  if item_id and 0 < item_id then
    local cfg = item_module:get_cfg_by_id(item_id)
    if cfg then
      return cfg.rank or 0
    end
  end
  return 0
end

function item_module:item_bag_type_is_weapon(cfg_id)
  return item_module:get_item_bag_type_by_id(cfg_id) == ItemBagType.BagTypeWeapon.value__
end

function item_module:item_bag_type_is_tool(cfg_id)
  return item_module:get_item_bag_type_by_id(cfg_id) == ItemBagType.BagTypeTool.value__
end

function item_module:item_bag_type_is_clothes(cfg_id)
  return item_module:get_item_bag_type_by_id(cfg_id) == ItemBagType.BagTypeCloth.value__
end

function item_module:auto_use_recipe()
  if self._auto_eat_item == nil then
    return
  end
  if #self._auto_eat_item <= 0 then
    self._auto_eat_item = nil
    return
  end
  local item_data = self._auto_eat_item[1]
  table.remove(self._auto_eat_item, 1)
  item_module:play_eate_req(item_data)
end

function item_module:get_auto_use_recipe_num()
  if self._auto_eat_item == nil then
    return 0
  end
  return #self._auto_eat_item
end

function item_module:play_recipe_Anim(data)
  item_module:set_cur_learn_recipe_id(data.ItemConfID)
  item_module:open_learn_recipe_finish_page()
  self._recipe_configId = data.ItemConfID
  player_module:play_learn_anim(self._recipe_configId, function()
    lua_event_module:send_event(lua_event_module.event_type.show_learn_recipe_finish_page, item_module:get_cur_learn_recipe_id())
  end)
end

function item_module:set_cur_learn_recipe_id(item_id)
  self._cur_learn_recipe_id = item_id or 0
end

function item_module:get_cur_learn_recipe_id()
  return self._cur_learn_recipe_id or 0
end

function item_module:set_cur_make_item_id(item_id)
  self._cur_make_item_id = item_id or 0
end

function item_module:get_cur_make_item_id()
  return self._cur_make_item_id
end

function item_module:set_cur_make_item_num(num)
  self._cur_make_item_num = num or 0
end

function item_module:get_cur_make_item_num()
  return self._cur_make_item_num
end

function item_module:set_item_num_data(data)
  self._item_num_data = data
end

function item_module:get_item_num_data()
  return self._item_num_data
end

function item_module:option_is_handheld_item(cfg_id)
  return item_module:get_tool_and_perform_item_cfg_by_id(cfg_id) ~= nil
end

function item_module:set_is_flaunt(is_flaunt)
  self._is_flaunt = is_flaunt
end

function item_module:get_is_flaunt()
  return self._is_flaunt or false
end

function item_module:is_show_star(item_guid, item_data)
  if is_null(item_data) then
    item_data = back_bag_module:get_packet_data():GetItemByGUID(item_guid)
  end
  if not is_null(item_data) then
    local star_level = item_data.StarLevel
    if is_null(star_level) then
      return false
    end
    return 0 < star_level and star_level < 6
  end
  return false
end

function item_module:is_show_crown(item_guid, item_data)
  if is_null(item_data) then
    item_data = back_bag_module:get_packet_data():GetItemByGUID(item_guid)
  end
  if not is_null(item_data) then
    local star_level = item_data.StarLevel
    if is_null(star_level) then
      return false
    end
    return star_level == 6
  end
  return false
end

function item_module:check_item_countdown(server_data, is_bag)
  local rot_time = server_data.RotTime
  if rot_time < 0 or server_data.isSendRot then
    return false
  end
  if rot_time == 0 then
    if is_bag then
      back_bag_module:get_packet_data():CheckBagItemCountdown(server_data)
    else
      CsWarehouseModuleUtil.CheckWarehouseItemCountdown(server_data)
    end
    return true
  end
  return false
end

function item_module:check_tags(item_id, id_cfg, tbl_tags)
  if tbl_tags == nil or table.count(tbl_tags) <= 0 then
    return false
  end
  id_cfg = id_cfg or item_module:get_id_cfg_by_id(item_id)
  if not is_null(id_cfg) then
    local is_has_tag = true
    for _, tag in pairs(tbl_tags) do
      if not item_module:check_tag(item_id, id_cfg, tag) then
        is_has_tag = false
        break
      end
    end
    return is_has_tag
  end
  return false
end

function item_module:check_tag(item_id, id_cfg, tag)
  if tag == nil or tag <= 0 then
    return false
  end
  if item_id == nil or item_id <= 0 then
    if is_null(id_cfg) then
      return false
    end
    item_id = id_cfg.id
  end
  return TagUtil.config_has_tag(item_id, tag)
end

function item_module:item_is_recipe(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_ideacard)
end

function item_module:item_is_cooking_recipe(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_cookrecipe)
end

function item_module:is_hand_decoration(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool_onehandholditem)
end

function item_module:is_insect(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_animal_insect)
end

function item_module:is_organism(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism)
end

function item_module:is_animal(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_animal)
end

function item_module:is_river_fish(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_animal_fish_riverfish)
end

function item_module:is_marine_fish(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_animal_fish_seafish)
end

function item_module:is_reef_organism(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_animal_sealife)
end

function item_module:is_clothing(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.clothing)
end

function item_module:is_eyes(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.clothing_eyes)
end

function item_module:is_hair(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.clothing_hair)
end

function item_module:is_photo(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_photo)
end

function item_module:is_task_item(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.cfunction_taskitem)
end

function item_module:is_flyer(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_flyer)
end

function item_module:is_drift_box(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.driftbox)
end

function item_module:is_expansion_ticket(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_backpackexpansionticket)
end

function item_module:is_function_unlock(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_toolring)
end

function item_module:is_seed_bag(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool_tool_seedbag)
end

function item_module:is_growing_crop(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_plant_crop_growingcrop)
end

function item_module:is_mature_crop(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_plant_crop_maturecrop)
end

function item_module:is_tool(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool_tool)
end

function item_module:is_condiment(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.condiment)
end

function item_module:is_npc_photo(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.specialitem_photo_npcphoto)
end

function item_module:is_golden_ingredients(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.ingredients_ingredients_rank_ingredients_golden)
end

function item_module:is_purple_ingredients(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.ingredients_ingredients_rank_ingredients_purple)
end

function item_module:is_ingredients(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.ingredients)
end

function item_module:is_food(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.food)
end

function item_module:is_handheld_tool(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool)
end

function item_module:is_contain_cup(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.food_containtype_contain_cup)
end

function item_module:is_contain_coffee_cup(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool_performitem_coffeecup)
end

function item_module:is_road(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.unlockitem_unlockroad)
end

function item_module:is_furniture(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.furniture)
end

function item_module:is_wall_paper(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.furniture_hardsurfaces_wallpaneling)
end

function item_module:is_auto_use(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.cfunction_autouseitem)
end

function item_module:is_unlock_appearance_card(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.unlockappearancecard)
end

function item_module:is_luca_hold(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.chandheldtool_handheldtool_performitem_lucahold)
end

function item_module:is_clothing_handheld(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.clothing_handheld)
end

function item_module:is_building_pack(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.building_house_buildingpack)
end

function item_module:is_npc_photo_by_server_data(server_data)
  if is_null(server_data) then
    return false
  end
  local id_cfg = item_module:get_id_cfg_by_id(server_data.ConFigID)
  if is_null(id_cfg) then
    return false
  end
  return item_module:is_npc_photo(server_data.ConFigID, id_cfg)
end

function item_module:is_fruits_crop(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.organism_plant_crop_fruitscrop)
end

function item_module:is_eye_color_unlock(item_id, id_cfg)
  return item_module:check_tag(item_id, id_cfg, EntityTagTags.Tags.unlockappearancecard_unlockcolor_unlockeyecolor)
end

return item_module or {}
