hand_book_module = hand_book_module or {}

function hand_book_module:get_unlock_state()
  return false
end

function hand_book_module:_refresh_main_tips(item)
  local cfg = item.cfg
  if cfg then
    local is_show_red = hand_book_module:get_new_tips_show_state(cfg.id, table.contains(hand_book_module.all_furniture_type, cfg.bagtype))
    if is_show_red then
      hand_book_module:set_main_new_tips_show_state(true)
      EventCenter.Broadcast(EventID.LuaSetHandBookMainTipsShowState, true)
    end
  end
end

function hand_book_module:get_main_new_tips_show_state()
  if self._is_new_hand_book == nil then
    self._is_new_hand_book = false
  end
  return self._is_new_hand_book
end

function hand_book_module:set_main_new_tips_show_state(is_new)
  if is_new == self._is_new_hand_book then
    return
  end
  self._is_new_hand_book = is_new
end

function hand_book_module:set_new_tips_show_state(item_id)
  local count = math.floor(item_id / 64)
  if self._new_tips_states and self._new_tips_states[count] then
    local result = CsUIUtil.SetHandBookNewTip(item_id)
    self._new_tips_states[count] = result
    EventCenter.Broadcast(EventID.LuaSetHandBookRedState, nil)
  end
end

function hand_book_module:get_recipe_get_state(item_id)
  if item_id == nil or item_id < 0 then
    Logger.LogError("无效的ItemId!!! itemId = " .. item_id)
    return false
  end
  local recipe_cfg = recipe_module:get_recipe_cfg_by_item_id(item_id)
  local is_recipe_get = false
  if recipe_cfg then
    is_recipe_get = table.contains(self._all_recipe_ids, recipe_cfg.id)
  end
  return is_recipe_get
end

function hand_book_module:get_new_tips_show_state(id, is_furniture)
  local is_get = hand_book_module:get_item_get_state(id)
  if not is_get and is_furniture then
    is_get = hand_book_module:get_recipe_get_state(id)
  end
  local count = math.floor(id / 64)
  local index = id % 64
  if self._new_tips_states and self._new_tips_states[count] then
    return CsUIUtil.CheckNew(self._new_tips_states[count], index) and is_get
  end
  return false
end

function hand_book_module:get_furniture_is_make(id)
  local count = math.ceil(id / 64)
  local index = id % 64
  if self._furniture_make_states and count <= #self._furniture_make_states and CsUIUtil.CheckNew(self._furniture_make_states[count], index) then
    return true
  end
  return false
end

function hand_book_module:get_item_get_state(id)
  local count = math.floor(id / 64)
  local index = id % 64
  if self._item_get_states and self._item_get_states[count] and not CsUIUtil.CheckNew(self._item_get_states[count], index) then
    return true
  end
  return back_bag_module:get_packet_data() and back_bag_module:get_item_num(id) > 0
end

function hand_book_module:get_item_have_num(id)
  return back_bag_module:get_item_num(id) or 0
end

function hand_book_module:get_red_num_by_show_type(show_type)
  local all_cfg = hand_book_module:get_item_cfg_by_show_type(show_type)
  if all_cfg == nil then
    return 0
  end
  local show_num = 0
  for _, cfg in pairs(all_cfg) do
    if hand_book_module:get_new_tips_show_state(cfg.id, show_type == hand_book_module.hand_book_type_furniture) then
      show_num = show_num + 1
    end
  end
  return show_num
end

function hand_book_module:refresh_server_data()
  self._all_recipe_ids = list_to_table(CsRecipeModuleUtil.recipeData.recipeList) or {}
  hand_book_module:_refresh_item_get_state()
  hand_book_module:_refresh_new_tips_state()
  hand_book_module:_refresh_furniture_make_state()
end

function hand_book_module:_refresh_furniture_make_state()
  self._furniture_make_states = {}
  local state
  for _, v in ipairs(hand_book_module.get_furniture_make_types) do
    state = CsUIUtil.GetPlayerNewTipData(v)
    table.insert(self._furniture_make_states, state)
  end
end

function hand_book_module:_refresh_new_tips_state()
  self._new_tips_states = {}
  local state
  for _, v in pairs(hand_book_module.get_new_tips_types) do
    state = CsUIUtil.GetPlayerNewTipData(v)
    self._new_tips_states[v.value__ - 1400] = state
  end
end

function hand_book_module:_refresh_item_get_state()
  self._item_get_states = {}
  local state
  for _, v in pairs(hand_book_module.item_get_state_types) do
    state = CsUIUtil.GetPlayerNewTipData(v)
    self._item_get_states[v.value__ - 1600] = state
  end
end

function hand_book_module:open_hand_book_tips(data)
  UIManagerInstance:open("UI/HandBook/HandBookDialog", data)
end

function hand_book_module:open_hand_book_info_tips(data)
  UIManagerInstance:open("UI/HandBook/HandBookInfoDialog", data)
end

return hand_book_module or {}
