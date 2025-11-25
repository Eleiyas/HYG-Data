galactic_bazaar_module = galactic_bazaar_module or {}

function galactic_bazaar_module:add_event()
  galactic_bazaar_module:remove_event()
  self._events = {}
  self._events[EventID.SceneActivity.OnSceneActivityJoin] = pack(self, galactic_bazaar_module._init_match_state)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function galactic_bazaar_module:_init_match_state(activity_id)
  if activity_id ~= galactic_bazaar_module.activity_id then
    return
  end
  galactic_bazaar_module._match_state = true
end

function galactic_bazaar_module:set_match_state(state)
  galactic_bazaar_module._match_state = state
end

function galactic_bazaar_module:set_match_state_to_open_tool(state)
  galactic_bazaar_module._match_state_to_open_tool = state
end

function galactic_bazaar_module:get_match_state_to_open_tool()
  return galactic_bazaar_module._match_state_to_open_tool
end

function galactic_bazaar_module:get_match_state()
  return galactic_bazaar_module._match_state
end

function galactic_bazaar_module:open_dancing_panel(args)
  if is_null(args) then
    return
  end
  self.dancing_action = args.reactionAction
  self.is_show_score = args.IsShowScore
  self.cur_show_player_uid = args.PlayerUid
  self.pre_count_down = is_null(args.PreCountDown) and 0 or args.PreCountDown
  local _, panel = UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarDancingPage", "dancing")
end

function galactic_bazaar_module:open_dance_finished_panel(args)
  self.cur_show_player = tonumber(args)
  local page = UIManagerInstance:is_show("UI/GalacticBazaar/GalacticBazaarDancingPage")
  if page then
    page:open_dance_finished_panel()
  else
    UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarDancingPage", "dance_finished")
  end
end

function galactic_bazaar_module:open_dance_settlement_page()
  self.cur_player_settlement_info = galactic_bazaar_module:get_dance_settlement_info(player_module:get_player_uid())
  self.cur_player_appraise = galactic_bazaar_module:get_dance_appraise(self.cur_player_settlement_info.PlayerUid)
  self.music_id = CsSceneActivityModuleUtil.GetDanceMusicId(galactic_bazaar_module.activity_id)
  self.rank = galactic_bazaar_module:Get_dance_finish_score_rank()[self.cur_player_settlement_info.PlayerUid]
  self.total_score = galactic_bazaar_module:get_dance_settlement_info_slider()
  UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarDanceSettlementPage")
end

function galactic_bazaar_module:_on_scene_activity_player_changed(activity_id)
  if activity_id ~= galactic_bazaar_module.activity_id then
    return
  end
  galactic_bazaar_module:dance_activity_matching_player_list()
end

function galactic_bazaar_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function galactic_bazaar_module:generate_and_refreshitems(uiwindow, pool, item_datas, prefab_transform, parent_transform, item_cls, refresh_callback)
  if is_null(uiwindow) or is_null(pool) or is_null(prefab_transform) or is_null(parent_transform) then
    Logger.LogWarning("common item tool - required parameters are null")
    return
  end
  if is_null(pool) then
    Logger.LogWarning("item_pool is null")
    return
  end
  self:reset_items(pool.active, pool.pool)
  pool.active = {}
  for id, item_data in pairs(item_datas) do
    self:add_item(uiwindow, pool.pool, pool.active, prefab_transform, parent_transform, item_cls, item_data, refresh_callback)
  end
end

function galactic_bazaar_module:add_item(uiwindow, item_pool, active_items, prefab_transform, parent_transform, panel_class, item_data, refresh_callback)
  if is_null(uiwindow) or is_null(item_pool) or is_null(active_items) or is_null(prefab_transform) or is_null(parent_transform) then
    Logger.LogWarning(" required parameters are null")
    return nil
  end
  local item
  if 0 < #item_pool then
    item = table.remove(item_pool)
  else
    if is_null(prefab_transform.gameObject) then
      Logger.LogWarning(" prefab_transform.gameObject is null")
      return nil
    end
    local obj = UIUtil.load_prefab_set_parent(prefab_transform.gameObject, parent_transform)
    if is_null(obj) then
      Logger.LogWarning("failed to load prefab")
      return nil
    end
    if panel_class then
      item = uiwindow:add_panel(panel_class, obj)
      if is_null(item) then
        Logger.LogWarning(" failed to add panel")
        return nil
      end
    else
      item = obj
    end
  end
  if item.trans then
    item.trans:SetParent(parent_transform)
    item.trans:SetAsLastSibling()
    item:set_active(true)
  else
    item.transform:SetParent(parent_transform)
    item.transform:SetAsLastSibling()
    UIUtil.set_active(item, true)
  end
  if refresh_callback and type(refresh_callback) == "function" then
    refresh_callback(item, item_data)
  end
  table.insert(active_items, item)
  return item
end

function galactic_bazaar_module:reset_items(active_items, item_pool)
  for _, item in ipairs(active_items) do
    if item.trans then
      item:set_active(false)
    else
      UIUtil.set_active(item, false)
    end
    table.insert(item_pool, item)
  end
  active_items = {}
end

return galactic_bazaar_module
