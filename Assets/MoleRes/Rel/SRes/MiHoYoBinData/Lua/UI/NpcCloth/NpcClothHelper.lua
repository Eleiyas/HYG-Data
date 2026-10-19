local M = npc_cloth_module
local COIN_DEDUCT_TITLE_TEXT_KEY = "NpcCloth_txt_Popup_CoinDeduct_Title"
local COIN_DEDUCT_TIPS_TEXT_KEY = "NpcCloth_txt_Popup_CoinDeduct_Tips"

local function get_item_id(goods_or_item_id)
  if type(goods_or_item_id) == "number" then
    return goods_or_item_id
  end
  return goods_or_item_id and (goods_or_item_id.ItemID or goods_or_item_id.item_id or goods_or_item_id.id or goods_or_item_id.ConfigId or goods_or_item_id.ConfigID or goods_or_item_id.ConFigID) or 0
end

local function get_outfit_cfg(goods_or_item_id)
  local item_id = get_item_id(goods_or_item_id)
  if item_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BNpcOutfitsCfg), item_id)
end

local SHAPE_LIST = {
  1,
  2,
  3
}
local SHAPE_ID_BY_KEY = {
  NpcSmall = 1,
  NpcMedium = 2,
  NpcBig = 3
}
local SHAPE_KEY_BY_ID = {
  [1] = "NpcSmall",
  [2] = "NpcMedium",
  [3] = "NpcBig"
}
local third_classify_slot_cache = {}
local slot_try_on_anim_cache = {}
local outfit_slot_set_cache = {}
local player_same_outfit_cache = {}
local coin_not_enough_text

local function safe_get_field(source, field_name)
  if source == nil then
    return nil
  end
  local ok, value = pcall(function()
    return source[field_name]
  end)
  if ok then
    return value
  end
  return nil
end

local function get_first_field(source, field_name_list)
  for _, field_name in ipairs(field_name_list) do
    local value = safe_get_field(source, field_name)
    if value ~= nil then
      return value
    end
  end
  return nil
end

local function get_third_classify_fst_classify_id(third_classify_id)
  third_classify_id = tonumber(third_classify_id) or 0
  if third_classify_id <= 0 then
    return 0
  end
  local cached_slot = third_classify_slot_cache[third_classify_id]
  if cached_slot then
    return cached_slot
  end
  for _, shape in ipairs(SHAPE_LIST) do
    local third_cfg = ExcelDataUtil.get_value(typeof(BNpcThidClassifyCfg), third_classify_id, shape)
    if not is_null(third_cfg) and 0 < (third_cfg.fstclassify or 0) then
      third_classify_slot_cache[third_classify_id] = third_cfg.fstclassify
      return third_cfg.fstclassify
    end
  end
  return 0
end

local function get_third_classify_slot_set(third_classify_id)
  third_classify_id = tonumber(third_classify_id) or 0
  if third_classify_id <= 0 then
    return nil
  end
  local cached = outfit_slot_set_cache[third_classify_id]
  if cached ~= nil then
    return cached
  end
  local result = {}
  for _, shape in ipairs(SHAPE_LIST) do
    local third_cfg = ExcelDataUtil.get_value(typeof(BNpcThidClassifyCfg), third_classify_id, shape)
    if not is_null(third_cfg) and string.is_valid(third_cfg.slot) then
      for _, slot_str in ipairs(lua_str_split(third_cfg.slot, ";", true)) do
        local slot_id = tonumber(slot_str) or 0
        if 0 < slot_id then
          result[slot_id] = true
        end
      end
      break
    end
  end
  if next(result) == nil then
    result = nil
  end
  outfit_slot_set_cache[third_classify_id] = result
  return result
end

local function try_get_cfg_localized_name(cfg)
  if cfg == nil or is_null(cfg) then
    return nil
  end
  return cfg.name
end

function M.get_outfit_cfg(goods_or_item_id)
  return get_outfit_cfg(goods_or_item_id)
end

function M.get_outfit_npc_id(goods_or_item_id)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  return outfit_cfg and (outfit_cfg.npcid or 0) or 0
end

function M.is_npc_cloth_item(goods_or_item_id)
  return get_outfit_cfg(goods_or_item_id) ~= nil
end

function M.get_player_same_outfit_ids(item_id, item_cfg)
  item_id = get_item_id(item_id)
  if item_id <= 0 or M.is_npc_cloth_item(item_id) then
    return nil
  end
  if player_same_outfit_cache[item_id] ~= nil then
    return player_same_outfit_cache[item_id]
  end
  local outfit_ids
  for _, outfit_cfg in pairs(ExcelDataUtil.get_table(typeof(BNpcOutfitsCfg)) or {}) do
    if not is_null(outfit_cfg) and outfit_cfg.playerclothid == item_id then
      outfit_ids = outfit_ids or {}
      outfit_ids[#outfit_ids + 1] = outfit_cfg.id
    end
  end
  player_same_outfit_cache[item_id] = outfit_ids or false
  return outfit_ids
end

function M.has_player_same_npc_cloth(item_id, item_cfg)
  local outfit_ids = M.get_player_same_outfit_ids(item_id, item_cfg)
  return outfit_ids ~= nil and outfit_ids ~= false and 0 < #outfit_ids
end

function M.get_goods_key(goods)
  return goods and (goods.GUID or goods.ItemID or 0) or 0
end

function M.get_outfit_slot_key(goods_or_item_id)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if not outfit_cfg then
    return get_item_id(goods_or_item_id)
  end
  local third_classify_id = outfit_cfg.thirdclassifyid or 0
  local fst_classify_id = get_third_classify_fst_classify_id(third_classify_id)
  if 0 < fst_classify_id then
    return fst_classify_id
  end
  if 0 < third_classify_id then
    local fallback_slot = math.floor(third_classify_id / 1000)
    third_classify_slot_cache[third_classify_id] = fallback_slot
    return fallback_slot
  end
  return outfit_cfg.id or get_item_id(goods_or_item_id)
end

function M.get_outfit_slot_set(goods_or_item_id)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if not outfit_cfg then
    return {}
  end
  local slot_set = get_third_classify_slot_set(outfit_cfg.thirdclassifyid or 0)
  return slot_set or {}
end

function M.get_outfit_fst_classify_id(goods_or_item_id)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if outfit_cfg then
    local fst_classify_id = get_third_classify_fst_classify_id(outfit_cfg.thirdclassifyid or 0)
    if 0 < fst_classify_id then
      return fst_classify_id
    end
  end
  return M.get_outfit_slot_key(goods_or_item_id)
end

function M.get_fst_classify_cfg(fst_id)
  fst_id = tonumber(fst_id) or 0
  if fst_id <= 0 then
    return nil
  end
  local cfg = ExcelDataUtil.get_value(typeof(BNpcFstClassifyCfg), fst_id)
  if cfg == nil or is_null(cfg) then
    return nil
  end
  return cfg
end

function M.get_fst_classify_title(fst_id)
  fst_id = tonumber(fst_id) or 0
  if fst_id <= 0 then
    return tostring(fst_id)
  end
  local title = try_get_cfg_localized_name(M.get_fst_classify_cfg(fst_id))
  if not string.is_valid(title) then
    title = tostring(fst_id)
  end
  return title
end

function M.get_outfit_try_on_anim(goods_or_item_id)
  local slot_key = M.get_outfit_slot_key(goods_or_item_id)
  if slot_key <= 0 then
    return ""
  end
  local cached_anim = slot_try_on_anim_cache[slot_key]
  if cached_anim ~= nil then
    return cached_anim
  end
  local store_cfg = ExcelDataUtil.get_value(typeof(BNpcClothStoreCfg), slot_key)
  local anim = store_cfg and store_cfg.clothtypeanim or ""
  if not string.is_valid(anim) then
    anim = ""
  end
  slot_try_on_anim_cache[slot_key] = anim
  return anim
end

function M.get_shape_id_by_key(shape_key)
  return SHAPE_ID_BY_KEY[shape_key] or tonumber(shape_key) or 0
end

function M.get_shape_key_by_id(shape_id)
  return SHAPE_KEY_BY_ID[tonumber(shape_id) or 0]
end

function M.get_default_shape_list()
  return SHAPE_LIST
end

function M.normalize_selected_npc_by_shape(source)
  local result = {}
  for shape, npc_id in pairs(source or {}) do
    local shape_id = type(shape) == "number" and shape or M.get_shape_id_by_key(shape)
    local normalized_npc_id = tonumber(npc_id) or 0
    if 0 < shape_id and 0 < normalized_npc_id then
      result[shape_id] = normalized_npc_id
    end
  end
  return result
end

function M.get_shape_id_by_avatar_shape_type(raw_shape)
  if not string.is_valid(raw_shape) then
    return 0
  end
  if string.find(raw_shape, "Small", 1, true) then
    return SHAPE_ID_BY_KEY.NpcSmall
  end
  if string.find(raw_shape, "Big", 1, true) then
    return SHAPE_ID_BY_KEY.NpcBig
  end
  return SHAPE_ID_BY_KEY.NpcMedium
end

function M.get_npc_shape_id(npc_id)
  local avatar_cfg = npc_id and ExcelDataUtil.get_value(typeof(BAvatarCfg), npc_id) or nil
  if avatar_cfg == nil then
    return 0
  end
  return M.get_shape_id_by_avatar_shape_type(avatar_cfg.avatarshapetype)
end

function M.get_npc_shape_key(npc_id)
  local avatar_cfg = npc_id and ExcelDataUtil.get_value(typeof(BAvatarCfg), npc_id) or nil
  local shape_id = avatar_cfg and M.get_shape_id_by_avatar_shape_type(avatar_cfg.avatarshapetype) or 0
  return M.get_shape_key_by_id(shape_id)
end

function M.get_npc_shape_code(npc_id)
  local shape_id = M.get_npc_shape_id(npc_id)
  if shape_id == 1 then
    return "S"
  elseif shape_id == 2 then
    return "M"
  elseif shape_id == 3 then
    return "L"
  else
    return nil
  end
end

function M.is_outfit_exclusive_to_npc(goods_or_item_id, npc_id)
  local outfit_npc_id = M.get_outfit_npc_id(goods_or_item_id)
  local current_npc_id = tonumber(npc_id) or 0
  if outfit_npc_id <= 0 or current_npc_id <= 0 then
    return false
  end
  return outfit_npc_id == current_npc_id
end

function M.copy_shop_goods(goods)
  if is_null(goods) then
    return nil
  end
  return {
    GUID = goods.GUID or 0,
    ItemID = goods.ItemID or 0,
    ItemCount = goods.ItemCount or 0,
    Price = goods.Price or 0,
    Discount = goods.Discount or 0,
    SellType = goods.SellType or 0,
    CAmount = goods.CAmount or 0,
    CTypepage = goods.CTypepage or 0,
    CItemtype = goods.CItemtype or 0,
    CP1 = goods.CP1 or 0,
    CCondition = goods.CCondition or 0,
    ConfIndex = goods.ConfIndex or 0,
    IsHostOnly = goods.IsHostOnly == true,
    CloseTime = goods.CloseTime or 0,
    IsHot = goods.IsHot == true,
    LockReason = goods.LockReason
  }
end

function M.build_goods_guid_map(shop_groups, target)
  local guid_map = target or {}
  table.clear(guid_map)
  for _, group_data in ipairs(shop_groups or {}) do
    for _, goods in ipairs(group_data.items or {}) do
      local goods_guid = goods.GUID or 0
      if 0 < goods_guid then
        guid_map[goods_guid] = goods
      end
    end
  end
  return guid_map
end

function M.find_goods_by_guid(shop_groups, goods_guid, goods_guid_map)
  goods_guid = goods_guid or 0
  if goods_guid <= 0 then
    return nil
  end
  if goods_guid_map and goods_guid_map[goods_guid] then
    return goods_guid_map[goods_guid]
  end
  for _, group_data in ipairs(shop_groups or {}) do
    for _, goods in ipairs(group_data.items or {}) do
      if (goods.GUID or 0) == goods_guid then
        return goods
      end
    end
  end
  return nil
end

function M.is_goods_protocol_locked(goods)
  return 0 < (tonumber(goods and goods.LockReason) or 0)
end

function M.is_goods_buyable(goods)
  if is_null(goods) then
    return false
  end
  if (goods.ItemCount or 0) <= 0 then
    return false
  end
  if goods.IsHostOnly == true and not player_module:is_local_player_scene_owner() then
    return false
  end
  return not M.is_goods_protocol_locked(goods)
end

function M.is_goods_wearable_by_shape(goods_or_item_id, shape)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if outfit_cfg == nil then
    return false
  end
  local shape_id = tonumber(shape) or 0
  if shape_id == SHAPE_ID_BY_KEY.NpcSmall then
    return string.is_valid(outfit_cfg.assetpath1)
  elseif shape_id == SHAPE_ID_BY_KEY.NpcMedium then
    return string.is_valid(outfit_cfg.assettpath2)
  elseif shape_id == SHAPE_ID_BY_KEY.NpcBig then
    return string.is_valid(outfit_cfg.assettpath3)
  end
  return true
end

function M.is_item_wearable_by_npc(goods_or_item_id, npc_id, shape)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if outfit_cfg == nil then
    return false
  end
  local current_npc_id = tonumber(npc_id) or 0
  local shape_id = tonumber(shape) or 0
  if shape_id <= 0 then
    return false
  end
  if 0 < (outfit_cfg.npcid or 0) and not M.is_outfit_exclusive_to_npc(goods_or_item_id, current_npc_id) then
    return false
  end
  return M.is_goods_wearable_by_shape(goods_or_item_id, shape_id)
end

function M.get_preset_item_key(item_data)
  local guid = tonumber(get_first_field(item_data, {
    "guid",
    "GUID",
    "Guid"
  }) or 0) or 0
  if 0 < guid then
    local source_type = get_first_field(item_data, {
      "source_type",
      "sourceType"
    }) or 0
    return tostring(source_type) .. ":" .. tostring(guid)
  end
  local item_id = get_item_id(item_data)
  if 0 < item_id then
    return item_id
  end
  local raw_key = get_first_field(item_data, {"key", "Key"})
  if raw_key ~= nil then
    return raw_key
  end
  return nil
end

function M.copy_item_snapshot(item, source_type, source_npc_id)
  if is_null(item) then
    return nil
  end
  local snapshot = {}
  if type(item) == "table" then
    for key, value in pairs(item) do
      local value_type = type(value)
      if value_type ~= "table" and value_type ~= "userdata" and value_type ~= "function" and value_type ~= "thread" then
        snapshot[key] = value
      end
    end
  end
  snapshot.item_id = tonumber(get_first_field(item, {
    "item_id",
    "ItemID",
    "id",
    "Id",
    "ConfigId",
    "ConfigID",
    "ConFigID"
  }) or 0) or 0
  snapshot.guid = tonumber(get_first_field(item, {
    "guid",
    "GUID",
    "Guid"
  }) or 0) or 0
  snapshot.make_guid = tonumber(get_first_field(item, {
    "make_guid",
    "MakeGUID",
    "MakeGuid"
  }) or 0) or 0
  snapshot.count = tonumber(get_first_field(item, {
    "count",
    "Count",
    "ItemCount",
    "item_count",
    "Num"
  }) or 0) or 0
  snapshot.source_type = source_type or get_first_field(item, {
    "source_type",
    "sourceType"
  }) or 0
  snapshot.source_npc_id = tonumber(source_npc_id or get_first_field(item, {
    "source_npc_id",
    "sourceNpcId"
  }) or 0) or 0
  snapshot.slot_key = M.get_outfit_slot_key(snapshot.item_id > 0 and snapshot.item_id or item)
  snapshot.key = M.get_preset_item_key(snapshot) or get_first_field(item, {"key", "Key"}) or snapshot.item_id
  return snapshot
end

function M.has_unwearable_goods_by_shape(goods_list, shape)
  for _, goods in ipairs(goods_list or {}) do
    if not M.is_goods_wearable_by_shape(goods, shape) then
      return true
    end
  end
  return false
end

function M.get_goods_size_text(goods_or_item_id)
  local outfit_cfg = get_outfit_cfg(goods_or_item_id)
  if outfit_cfg == nil then
    return ""
  end
  local sizes = {}
  if string.is_valid(outfit_cfg.assettpath3) then
    sizes[#sizes + 1] = "L"
  end
  if string.is_valid(outfit_cfg.assettpath2) then
    sizes[#sizes + 1] = "M"
  end
  if string.is_valid(outfit_cfg.assetpath1) then
    sizes[#sizes + 1] = "S"
  end
  return table.concat(sizes, "/")
end

function M.get_player_same_size_text(item_id, item_cfg)
  local outfit_ids = M.get_player_same_outfit_ids(item_id, item_cfg)
  if outfit_ids == nil or outfit_ids == false then
    return ""
  end
  local has_l = false
  local has_m = false
  local has_s = false
  for _, outfit_id in ipairs(outfit_ids) do
    local outfit_cfg = get_outfit_cfg(outfit_id)
    if outfit_cfg then
      has_l = has_l or string.is_valid(outfit_cfg.assettpath3)
      has_m = has_m or string.is_valid(outfit_cfg.assettpath2)
      has_s = has_s or string.is_valid(outfit_cfg.assetpath1)
    end
  end
  local sizes = {}
  if has_l then
    sizes[#sizes + 1] = "L"
  end
  if has_m then
    sizes[#sizes + 1] = "M"
  end
  if has_s then
    sizes[#sizes + 1] = "S"
  end
  return table.concat(sizes, "/")
end

function M.get_coin_not_enough_text()
  if not string.is_valid(coin_not_enough_text) then
    coin_not_enough_text = UIUtil.get_text_by_id("NpcCloth_AddGoods_NotEnough")
  end
  return coin_not_enough_text
end

function M.get_available_buy_balance()
  local ticket_num = back_bag_module:get_coin(back_bag_module.coin_type.npc_cloth_ticket) or 0
  local fragment_num = back_bag_module:get_coin(back_bag_module.coin_type.gold) or 0
  return math.max(ticket_num, 0) + math.max(fragment_num, 0)
end

function M.get_fragment_deduct_cost(total_price)
  local ticket_num = back_bag_module:get_coin(back_bag_module.coin_type.npc_cloth_ticket) or 0
  return math.max(total_price - math.max(ticket_num, 0), 0)
end

function M.show_coin_deduct_confirm(fragment_cost, confirm_callback)
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id(COIN_DEDUCT_TIPS_TEXT_KEY, tostring(fragment_cost)), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), UIUtil.get_text_by_id(COIN_DEDUCT_TITLE_TEXT_KEY))
  popup:set_callbacks(confirm_callback, nil, nil, nil)
  popup:show()
end

function M.clear_helper_cache()
  table.clear(third_classify_slot_cache)
  table.clear(slot_try_on_anim_cache)
  table.clear(outfit_slot_set_cache)
  table.clear(player_same_outfit_cache)
  coin_not_enough_text = nil
end

return M
