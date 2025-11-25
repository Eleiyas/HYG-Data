npc_house_order_module = npc_house_order_module or {}
local mi_tai_score_module_module = require("UI/MiTaiScore/Module/MiTaiScoreMain")
local star_item_cls = "UI/MiYouZhu/MiYouZhuStarItemPanel"
local tag_item_cls = "UI/MiYouZhu/MiYouZhuTagItemPanel"
local reward_item_cls = "UI/MiYouZhu/MiYouZhuRewardItemPanel"
local reward_item_list_panel_cls = "UI/MiYouZhu/MiYouZhuRewardItemListPanel"
local furniture_item_cls = "UI/MiYouZhu/MiYouZhuFurnitureItemPanel"
local best_item_cls = "UI/MiYouZhu/MiYouZhuBestItemPanel"

function npc_house_order_module:add_event()
  npc_house_order_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowHouseOrderFurnitureTip] = pack(self, npc_house_order_module._show_furniture_tip)
  self._events[EventID.LuaShowHouseOrderBestFurnitureTip] = pack(self, npc_house_order_module._show_best_furniture_tip)
  self._events[EventID.LuaShowHouseOrderTopScoreTip] = pack(self, npc_house_order_module._show_top_score_tip)
  self._events[EventID.LuaShowHouseOrderResultTip] = pack(self, npc_house_order_module._show_result_tip)
  self._events[EventID.LuaCloseHouseOrderTip] = pack(self, npc_house_order_module._close_tip)
  self._events[EventID.LuaSetDeliveryPerformanceFlag] = pack(self, npc_house_order_module._set_delivery_performance_flag)
  self._events[EventID.LuaShowHouseOrderFinish] = pack(self, npc_house_order_module._on_house_order_finish)
  self._events[EventID.LuaShowHouseOrderDetail] = pack(self, npc_house_order_module._show_order_detail)
  self._events[EventID.OnVirtualNpcCreateComplete] = pack(self, npc_house_order_module._on_npc_create)
  self._events[EventID.LuaReleaseForcedNpc] = pack(self, npc_house_order_module._release_forced_npc)
  self._events[EventID.NpcHouseOrderSwitchCameraPoint] = pack(self, npc_house_order_module._on_switch_camera_point)
  self._events[EventID.LuaSetLoadingState] = pack(self, npc_house_order_module.on_loading_end)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function npc_house_order_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function npc_house_order_module:_release_forced_npc()
  if self.house_order_data and self.house_order_data.force_pulled then
    CsNpcUtil.ResumeNpc(self.house_order_data.npc_guid, self.house_order_data.npc_id)
    self.house_order_data.force_pulled = false
  end
  if self.edit_order_data and self.edit_order_data.force_pulled then
    CsNpcUtil.ResumeNpc(self.edit_order_data.npc_guid, self.edit_order_data.npc_id)
    self.edit_order_data.force_pulled = false
  end
end

function npc_house_order_module:_on_npc_create(guid)
  if self.house_order_data and self.house_order_data.npc_guid == guid and self.house_order_data.wait_for_create then
    self.house_order_data.wait_for_create = false
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      self:_internal_play_accept_performance()
    end)
  end
  if self.edit_order_data and self.edit_order_data.npc_guid == guid and self.edit_order_data.wait_for_create then
    self.edit_order_data.wait_for_create = false
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      self:_internal_play_evaluate_performance()
    end)
  end
end

function npc_house_order_module:_show_order_detail()
  if self.house_order_data.order then
    local data = {
      order_list = {
        self.house_order_data.order
      },
      is_performance_page = true
    }
    UIManagerInstance:open("UI/MiYouZhu/MiYouZhuOrderPage", data)
  end
end

function npc_house_order_module:_set_delivery_performance_flag(flag)
  self._need_enter_delivery_performance = flag
end

function npc_house_order_module:_on_house_order_finish()
  self:show_delivery_performance()
end

function npc_house_order_module:show_delivery_performance()
  if not self.edit_order_data then
    UIManagerInstance:open("UI/MiYouZhu/MiYouZhuOrderFinishPage")
    return
  end
  local guid = UIManagerInstance:open("UI/Performance/BlankPage", nil)
  
  local function on_early_stop()
    UIManagerInstance:close(guid)
    UIManagerInstance:open("UI/MiYouZhu/MiYouZhuOrderFinishPage")
  end
  
  EntityUtil.hide_or_show_all_avatar(false, 0.1)
  CsBlackScreenManagerUtil.ShowBlackScreen(0)
  self.delivery_npc = EntityUtil.create_virtual_npc(self.edit_order_data.npc_id)
  if self.delivery_npc ~= 0 then
    self:init_camera_controller(function(succeeded)
      CsBlackScreenManagerUtil.HideBlackScreen(0.15)
      if succeeded then
        self:start_order_camera()
        if self.camera_ctrl then
          self.camera_ctrl:SwitchToCameraPointByName("Walk", true)
        end
        CsUIUtil.MiTaiEvaluateResultShow(self.delivery_npc, function(finish)
          if finish then
            CsBlackScreenManagerUtil.StartBlackScreen(0.2, 0.4, 0.2, function()
              if self.camera_ctrl then
                self.camera_ctrl:SwitchToCameraPointByName("Stand", false)
              end
              local succ, pos = self:_get_empty_pos()
              if succ then
                EntityUtil.stop_avavar_move(self.delivery_npc)
                EntityUtil.set_entity_position_by_guid(self.delivery_npc, pos.x, pos.y, pos.z)
                if self.camera_look and self.camera_target then
                  self.camera_look:LookAt(self.camera_target)
                  self.camera_look:SetLocalEulerAnglesX(0)
                  self.camera_look:SetLocalEulerAnglesZ(0)
                  local target_quaternion = self.camera_look.rotation
                  EntityUtil.set_entity_rotation_by_guid(self.delivery_npc, target_quaternion.x, target_quaternion.y, target_quaternion.z, target_quaternion.w)
                end
                CsPerformanceManagerUtil.ShowPerformance(10000007005, function()
                  self:delivery_performance_end()
                  self:exit_order_camera()
                  CsCoroutineManagerUtil.InvokeNextFrame(function()
                    UIManagerInstance:open("UI/MiYouZhu/MiYouZhuOrderFinishPage")
                  end)
                end, self.delivery_npc)
              else
                self:delivery_performance_end()
                self:exit_order_camera()
                on_early_stop()
              end
            end)
          else
            self:delivery_performance_end()
            self:exit_order_camera()
            on_early_stop()
          end
        end)
      else
        self:delivery_performance_end()
        self:exit_order_camera()
        on_early_stop()
      end
    end)
  else
    on_early_stop()
  end
end

function npc_house_order_module:_get_empty_pos()
  local succ, pos = GameSceneUtility.TryGetEmptyPos2X2()
  if not succ then
    succ, pos = GameSceneUtility.TryGetEmptyPos()
  end
  return succ, pos
end

function npc_house_order_module:delivery_performance_end()
  if self.delivery_npc and self.delivery_npc ~= 0 then
    EntityUtil.destroy_entity_by_guid(self.delivery_npc)
  end
  EntityUtil.hide_or_show_all_avatar(true, 0.1)
  self.delivery_npc = 0
end

function npc_house_order_module:_show_finish_page()
  UIManagerInstance:open("UI/MiYouZhu/MiYouZhuOrderFinishPage")
end

function npc_house_order_module:_show_furniture_tip(data)
  UIManagerInstance:open("UI/NpcHouseOrder/Tip/NpcHouseOrderTip", "ShowFurniture")
end

function npc_house_order_module:_show_best_furniture_tip(data)
  UIManagerInstance:open("UI/NpcHouseOrder/Tip/NpcHouseOrderTip", "ShowBestFurniture")
end

function npc_house_order_module:_show_result_tip(data)
  UIManagerInstance:open("UI/NpcHouseOrder/Tip/NpcHouseOrderTip", "ShowResult")
end

function npc_house_order_module:_show_top_score_tip(data)
  UIManagerInstance:open("UI/NpcHouseOrder/Tip/NpcHouseOrderTip", "ShowTopScore")
end

function npc_house_order_module:_close_tip()
  local page = UIManagerInstance:is_show("UI/NpcHouseOrder/Tip/NpcHouseOrderTip")
  if page ~= nil and page.is_active then
    UIManagerInstance:close(page.guid)
  end
end

function npc_house_order_module:_on_switch_camera_point(data)
  if data and self.camera_ctrl then
    local pointName = data.PointName
    local instant = data.Instant or false
    local callback = data.Callback
    if string.is_valid(pointName) then
      self.camera_ctrl:SwitchToCameraPointByName(pointName, instant, callback)
    elseif callback then
      callback(-1)
    end
  end
end

function npc_house_order_module:on_loading_end(state)
  npc_house_order_module:dispose_camera_controller()
  if state then
    return
  end
  if self:check_npc_house_order() and GameSceneUtility.IsCurrentSceneNpcHome(self.house_order_data.npc_id) then
    npc_house_order_module:play_accept_performance()
  end
end

function npc_house_order_module:play_accept_performance()
  self.house_order_data.force_pulled = false
  self.house_order_data.npc_guid = 0
  self.house_order_data.wait_for_create = false
  npc_house_order_module:pull_npc_to_home_for_accept(self.house_order_data.npc_id)
  if self.house_order_data.force_pulled == false then
    self:_internal_play_accept_performance()
  end
end

function npc_house_order_module:_internal_play_accept_performance()
  local npc_entity = GameplayUtilities.Entities.GetEntity(self.house_order_data.npc_guid)
  if npc_entity then
    UIManagerInstance:close_all_stack_window_without_main_page()
    
    local function accept_callback()
      CsMiTaiModuleUtil.PlaceMitaiDecorationOrder(self.house_order_data.order.OrderCfgId, function(rsp)
        if rsp and rsp.Retcode == 0 then
          lua_event_module:send_event(lua_event_module.event_type.on_npc_house_order_placed)
        end
      end)
    end
    
    CsPerformanceManagerUtil.ShowPerformance(self.house_order_data.quest_cfg.performancid1, accept_callback, npc_entity.Guid)
  end
end

function npc_house_order_module:play_evaluate_performance(order)
  local quest_cfg = self:get_npc_design_quest_cfg(order.OrderCfgId)
  if quest_cfg then
    self.edit_order_data = {
      order = order,
      quest_cfg = quest_cfg,
      npc_id = quest_cfg.npcid,
      force_pulled = false,
      npc_guid = 0,
      wait_for_create = false
    }
    npc_house_order_module:pull_npc_to_home_evaluate(quest_cfg.npcid)
    if self.edit_order_data.force_pulled == false then
      self:_internal_play_evaluate_performance()
    end
  end
end

function npc_house_order_module:_internal_play_evaluate_performance()
  CsBlackScreenManagerUtil.HideBlackScreen(0.25, function()
    local npc_entity = GameplayUtilities.Entities.GetEntity(self.edit_order_data.npc_guid)
    if npc_entity then
      UIManagerInstance:close_all_stack_window_without_main_page()
      self._need_enter_delivery_performance = false
      
      local function finish_callback()
        if self._need_enter_delivery_performance then
          EventCenter.Broadcast(EventID.LuaShowHouseOrderFinish, nil)
        end
      end
      
      CsPerformanceManagerUtil.ShowPerformance(self.edit_order_data.quest_cfg.performancid2, finish_callback, npc_entity.Guid)
    end
  end)
end

function npc_house_order_module:add_entry(uiwindow, entry_pool, active_entries, prefab_transform, parent_transform, panel_class, refresh_callback)
  local entry
  if 0 < #entry_pool then
    entry = table.remove(entry_pool)
  else
    local obj = UIUtil.load_prefab_set_parent(prefab_transform.gameObject, parent_transform)
    if panel_class then
      entry = uiwindow:add_panel(panel_class, obj)
    else
      entry = obj
    end
  end
  if entry.trans then
    entry.trans:SetParent(parent_transform)
    entry.trans:SetAsLastSibling()
    entry:set_active(true)
  else
    entry.transform:SetParent(parent_transform)
    entry.transform:SetAsLastSibling()
    UIUtil.set_active(entry, true)
  end
  if refresh_callback and type(refresh_callback) == "function" then
    refresh_callback(entry)
  end
  table.insert(active_entries, entry)
  return entry
end

function npc_house_order_module:clear_and_recycle_entries(active_entries, entry_pool)
  for _, entry in ipairs(active_entries) do
    if entry.trans then
      entry:set_active(false)
    else
      UIUtil.set_active(entry, false)
    end
    table.insert(entry_pool, entry)
  end
  table.clear(active_entries)
end

function npc_house_order_module:refresh_star_items(star_root, star_item, order_data, pool, use_recent_score)
  UIUtil.set_active(star_item, false)
  self:clear_and_recycle_entries(pool.active, pool.pool)
  pool.active = {}
  if not order_data or not order_data.OrderCfgId then
    return 0, 0
  end
  local order_id = order_data.OrderCfgId
  local score = use_recent_score and order_data.MostRecentScore or order_data.HistoryMaxScore or 0
  local total_stars = self:get_total_star_count(order_id)
  local achieved_stars = self:get_star_count_by_score(order_id, score)
  for i = 1, total_stars do
    local is_achieved = i <= achieved_stars
    local star_item_instance = self:add_entry(nil, pool.pool, pool.active, star_item, star_root, nil, function(entry)
      local state_cmpt = UIUtil.find_cmpt(entry, "", typeof(UIStateChangeGroup))
      if state_cmpt then
        state_cmpt:SetState(is_achieved and 0 or 1)
      end
    end)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(star_root)
  return total_stars, achieved_stars
end

function npc_house_order_module:refresh_tag_list(uiwindow, known_tag_root, known_tag_item, known_tag_splitter, order_data, pools)
  self:clear_and_recycle_entries(pools.tag_item.active, pools.tag_item.pool)
  self:clear_and_recycle_entries(pools.tag_splitter.active, pools.tag_splitter.pool)
  pools.tag_item.active = {}
  pools.tag_splitter.active = {}
  UIUtil.set_active(known_tag_item, false)
  if known_tag_splitter then
    UIUtil.set_active(known_tag_splitter, false)
  end
  if not order_data or not order_data.OrderCfgId then
    return
  end
  local style_list = self:get_house_order_style_list(order_data.OrderCfgId)
  if not style_list or #style_list == 0 then
    return
  end
  local known_tags = style_list
  local unknown_tags = {}
  local is_first = true
  for _, style in ipairs(known_tags) do
    self:add_entry(uiwindow, pools.tag_item.pool, pools.tag_item.active, known_tag_item, known_tag_root, tag_item_cls, function(entry)
      entry:refresh({
        text = TagUtil.get_tag_name_in_game_by_string(style.tag),
        is_known = true
      })
    end)
  end
  UIUtil.set_active(known_tag_root, 0 < #known_tags)
end

function npc_house_order_module:refresh_tag_list_one_list(uiwindow, known_tag_root, known_tag_item, known_tag_splitter, order_data, pools)
  npc_house_order_module:clear_and_recycle_entries(pools.tag_item.active, pools.tag_item.pool)
  if known_tag_splitter then
    npc_house_order_module:clear_and_recycle_entries(pools.tag_splitter.active, pools.tag_splitter.pool)
  end
  UIUtil.set_active(known_tag_item, false)
  if known_tag_splitter then
    UIUtil.set_active(known_tag_splitter, false)
  end
  if not order_data or not order_data.OrderCfgId then
    return
  end
  local style_list = self:get_house_order_style_list(order_data.OrderCfgId)
  if not style_list or #style_list == 0 then
    return
  end
  local known_tags = style_list
  local unknown_tags = {}
  local is_first_tag = true
  for _, style in ipairs(known_tags) do
    if not is_first_tag then
      if known_tag_splitter then
        self:add_entry(uiwindow, pools.tag_splitter.pool, pools.tag_splitter.active, known_tag_splitter, known_tag_root, nil)
      end
    else
      is_first_tag = false
    end
    self:add_entry(uiwindow, pools.tag_item.pool, pools.tag_item.active, known_tag_item, known_tag_root, nil, function(entry)
      local text_cmpt = UIUtil.find_text(entry, "")
      if text_cmpt then
        text_cmpt.text = TagUtil.get_tag_name_in_game_by_string(style.tag)
      end
    end)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(known_tag_root)
end

function npc_house_order_module:refresh_reward_list(uiwindow, order_data, pools, reward_root, reward_prefab)
  UIUtil.set_active(reward_prefab, false)
  self:clear_and_recycle_entries(pools.reward_item.active, pools.reward_item.pool)
  pools.reward_item.active = {}
  if not order_data or not order_data.OrderCfgId then
    return
  end
  local reward_list = self:get_reward_list(order_data.OrderCfgId)
  local max_take_reward_score = order_data.MaxTakeRewardScore or 0
  local max_star_count = self:get_total_star_count(order_data.OrderCfgId)
  if reward_list and 0 < #reward_list then
    table.sort(reward_list, function(a, b)
      return a.star < b.star
    end)
    for _, reward_info in ipairs(reward_list) do
      local state = max_take_reward_score >= reward_info.point and 0 or 1
      local state_num = reward_info.star == max_star_count and 1 or 0
      local random_pool_cfg = LocalDataUtil.get_value(typeof(CS.BRandomPoolCfg), reward_info.reward)
      if random_pool_cfg then
        do
          local item_infos = {}
          for _, pool_entry in ipairs(list_to_table(random_pool_cfg)) do
            table.insert(item_infos, {
              item_id = pool_entry.configid,
              item_count = pool_entry.num
            })
          end
          if 0 < #item_infos then
            local reward_data = {
              StarCount = reward_info.star,
              ItemInfos = item_infos
            }
            self:add_entry(uiwindow, pools.reward_item.pool, pools.reward_item.active, reward_prefab, reward_root, reward_item_list_panel_cls, function(panel)
              panel:refresh(reward_data, state, state_num, order_data.OrderCfgId)
            end)
          end
        end
      end
    end
  end
end

function npc_house_order_module:refresh_furniture_order_list(uiwindow, order_data, pools, furn_root_item, show_progress, use_fake)
  self:clear_and_recycle_entries(pools.furniture_item.active, pools.furniture_item.pool)
  self:clear_and_recycle_entries(pools.best_furniture_item.active, pools.best_furniture_item.pool)
  self:clear_and_recycle_entries(pools.extra_furniture_item.active, pools.extra_furniture_item.pool)
  if not order_data then
    return
  end
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list or #req_list == 0 then
    return
  end
  local furniture_list
  if use_fake then
    furniture_list = CsRoomManagerUtil.GetAllFurnitureEntitiesInRoom()
  end
  local _, condition_satisfaction = self:check_order_condition(order_data, furniture_list)
  for i, req_cfg in ipairs(req_list) do
    if req_cfg.ordertype == 1 then
      local furniture_root = furn_root_item[1].trans_furn_list
      local furniture_prefab = furn_root_item[1].trans_furn
      local satisfied_count = 0
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
      end
      self:add_entry(uiwindow, pools.furniture_item.pool, pools.furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
        entry:refresh(req_cfg, satisfied_count, req_cfg.number, false, show_progress)
      end)
      LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
    elseif req_cfg.ordertype == 2 then
      local furniture_root = furn_root_item[2].trans_furn_list
      local furniture_prefab = furn_root_item[2].trans_furn
      local satisfied_count = 0
      local is_best_satisfied = false
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
        is_best_satisfied = condition_satisfaction[i].best_choice_satisfied
      end
      self:add_entry(uiwindow, pools.best_furniture_item.pool, pools.best_furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
        entry:refresh(req_cfg, satisfied_count, req_cfg.number, false, show_progress, is_best_satisfied)
      end)
      LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
    elseif req_cfg.ordertype == 3 then
      local furniture_root = furn_root_item[3].trans_furn_list
      local furniture_prefab = furn_root_item[3].trans_furn
      local satisfied_count = 0
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
      end
      self:add_entry(uiwindow, pools.extra_furniture_item.pool, pools.extra_furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
        entry:refresh(req_cfg, satisfied_count, req_cfg.number, false, show_progress)
      end)
      LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
    end
  end
end

function npc_house_order_module:refresh_best_furniture_name_list(uiwindow, pools, furniture_root, furniture_prefab, is_best)
  if is_best then
    self:clear_and_recycle_entries(pools.best_furniture_item_pools.active, pools.best_furniture_item_pools.pool)
  else
    self:clear_and_recycle_entries(pools.extra_furniture_item_pools.active, pools.extra_furniture_item_pools.pool)
  end
  local order_data = CsMiTaiModuleUtil.curOrder
  if not order_data then
    return
  end
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list or #req_list == 0 then
    return
  end
  local _, condition_satisfaction = self:check_order_condition(order_data, CsRoomManagerUtil.GetAllFurnitureEntitiesInRoom())
  for i, req_cfg in ipairs(req_list) do
    if req_cfg.ordertype == 2 and is_best then
      local satisfied_count = 0
      local is_best_satisfied = false
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
        is_best_satisfied = condition_satisfaction[i].best_choice_satisfied
      end
      local item_cfg = self:get_furniture_cfg(req_cfg.bestfurnitureid)
      UIUtil.set_active(furniture_root, true)
      if item_cfg then
        self:add_entry(uiwindow, pools.best_furniture_item_pools.pool, pools.best_furniture_item_pools.active, furniture_prefab, furniture_root, best_item_cls, function(entry)
          entry:refresh_name(item_cfg.name)
        end)
      end
    elseif req_cfg.ordertype == 3 and not is_best then
      local extra_item_id = 0
      if condition_satisfaction and condition_satisfaction[i] then
        extra_item_id = condition_satisfaction[i].satisfied_furniture_id
      end
      local item_cfg = self:get_furniture_cfg(extra_item_id)
      UIUtil.set_active(furniture_root, true)
      if item_cfg then
        self:add_entry(uiwindow, pools.extra_furniture_item_pools.pool, pools.extra_furniture_item_pools.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
          entry:refresh_tips(item_cfg.name, item_cfg.icon)
        end)
      end
    end
  end
end

function npc_house_order_module:refresh_best_furniture_list(uiwindow, order_data, pools, furniture_root, furniture_prefab, use_real)
  UIUtil.set_active(furniture_prefab, false)
  self:clear_and_recycle_entries(pools.best_item.active, pools.best_item.pool)
  if not order_data then
    return
  end
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list or #req_list == 0 then
    return
  end
  local _, condition_satisfaction = self:check_order_condition(order_data, CsRoomManagerUtil.GetAllFurnitureEntitiesInRoom())
  for i, req_cfg in ipairs(req_list) do
    if req_cfg.bestfurnitureid ~= 0 then
      local is_finished_best = condition_satisfaction[i].best_choice_satisfied
      local item_cfg = self:get_furniture_cfg(req_cfg.bestfurnitureid)
      if item_cfg then
        self:add_entry(uiwindow, pools.best_item.pool, pools.best_item.active, furniture_prefab, furniture_root, best_item_cls, function(entry)
          entry:refresh(item_cfg, is_finished_best)
        end)
      end
    end
  end
end

function npc_house_order_module:refresh_furniture_list(uiwindow, order_data, pools, furniture_root, furniture_prefab, show_progress, use_real)
  UIUtil.set_active(furniture_prefab, false)
  self:clear_and_recycle_entries(pools.furniture_item.active, pools.furniture_item.pool)
  if not order_data then
    return
  end
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list or #req_list == 0 then
    return
  end
  local furniture_list = CsRoomManagerUtil.GetAllFurnitureEntitiesInRoom()
  local _, condition_satisfaction = self:check_order_condition(order_data, furniture_list)
  for i, req_cfg in ipairs(req_list) do
    if req_cfg.ordertype ~= 3 then
      local satisfied_count = 0
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
      end
      local is_mystery = false
      self:add_entry(uiwindow, pools.furniture_item.pool, pools.furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
        entry:refresh(req_cfg, satisfied_count, req_cfg.number, is_mystery, show_progress)
      end)
    end
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
end

function npc_house_order_module:refresh_submit_furniture_list(uiwindow, order_data, pools, furniture_root, furniture_prefab, show_progress, use_real)
  UIUtil.set_active(furniture_prefab, false)
  self:clear_and_recycle_entries(pools.furniture_item.active, pools.furniture_item.pool)
  if not order_data then
    return
  end
  local furn_list = self:get_cur_submit_furns(order_data)
  if not furn_list or #furn_list == 0 then
    return
  end
  for _, furn in ipairs(furn_list) do
    local cfg = self:get_furniture_cfg(furn.ItemId)
    self:add_entry(uiwindow, pools.furniture_item.pool, pools.furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
      entry:refresh_submit_furniture(cfg, furn.Count)
    end)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
end

function npc_house_order_module:refresh_new_rewards(uiwindow, order_data, pools, reward_root, reward_prefab, trans_reward_txt, first_open)
  UIUtil.set_active(reward_prefab, false)
  self:clear_and_recycle_entries(pools.reward_item.active, pools.reward_item.pool)
  pools.reward_item.active = {}
  if not order_data or not order_data.OrderCfgId then
    return
  end
  local reward_list = self:get_reward_list(order_data.OrderCfgId)
  if not reward_list or #reward_list == 0 then
    return
  end
  local most_recent_score = order_data.MostRecentScore or 0
  local max_take_reward_score = order_data.MaxTakeRewardScore or 0
  local max_star_count = self:get_total_star_count(order_data.OrderCfgId)
  table.sort(reward_list, function(a, b)
    return a.point < b.point
  end)
  local reward_infos_to_process = {}
  local has_reward = false
  if first_open then
    self._cache_reward_info = {}
    for _, reward_info in ipairs(reward_list) do
      if most_recent_score >= reward_info.point and max_take_reward_score < reward_info.point then
        table.insert(self._cache_reward_info, {
          star = reward_info.star,
          reward = reward_info.reward,
          state_num = reward_info.star == max_star_count and 1 or 0
        })
      end
    end
    reward_infos_to_process = self._cache_reward_info
  else
    reward_infos_to_process = self._cache_reward_info or {}
  end
  for _, cached_info in ipairs(reward_infos_to_process) do
    local state = 0
    local state_num = cached_info.state_num
    local random_pool_cfg = LocalDataUtil.get_value(typeof(CS.BRandomPoolCfg), cached_info.reward)
    if random_pool_cfg then
      has_reward = true
      for _, pool_entry in ipairs(list_to_table(random_pool_cfg)) do
        self:add_entry(uiwindow, pools.reward_item.pool, pools.reward_item.active, reward_prefab, reward_root, "UI/MiYouZhu/MiYouZhuSingleRewardItem", function(panel)
          panel:refresh({
            item_id = pool_entry.configid,
            item_count = pool_entry.num,
            StarCount = cached_info.star
          }, state, state_num)
        end)
      end
    end
  end
  UIUtil.set_active(trans_reward_txt, has_reward)
  UIUtil.set_active(reward_root, has_reward)
  LayoutRebuilder.ForceRebuildLayoutImmediate(reward_root)
end

function npc_house_order_module:refresh_brief_furniture_list(uiwindow, order_data, pools, furniture_root, furniture_prefab, show_progress)
  UIUtil.set_active(furniture_prefab, false)
  self:clear_and_recycle_entries(pools.furniture_item.active, pools.furniture_item.pool)
  pools.furniture_item.active = {}
  if not order_data then
    return
  end
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list or #req_list == 0 then
    return
  end
  local _, condition_satisfaction = self:check_order_condition(order_data, CsRoomManagerUtil.GetAllFurnitureEntitiesInRoom())
  for i, req_cfg in ipairs(req_list) do
    if req_cfg.ordertype == 1 or req_cfg.ordertype == 2 then
      local satisfied_count = 0
      if condition_satisfaction and condition_satisfaction[i] then
        satisfied_count = condition_satisfaction[i].satisfied_count
      end
      self:add_entry(uiwindow, pools.furniture_item.pool, pools.furniture_item.active, furniture_prefab, furniture_root, furniture_item_cls, function(entry)
        entry:refresh_as_brief_item(req_cfg, satisfied_count, req_cfg.number, show_progress)
      end)
    end
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(furniture_root)
end

function npc_house_order_module:beiwanglu_open_miyouzhu_page()
  if UIManagerInstance:is_show("UI/MiYouZhu/MiYouZhuAppPage") then
    return
  end
  UIManagerInstance:open("UI/MiYouZhu/MiYouZhuAppPage")
end

return npc_house_order_module
