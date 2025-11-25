overhead_hint_module = overhead_hint_module or {}
overhead_hint_module._cname = "overhead_hint_module"

function overhead_hint_module:init()
  self._events = nil
  self._is_loading = false
  self._is_playing_cutscene = false
  overhead_hint_module:reset_server_data()
  overhead_hint_module:add_event()
end

function overhead_hint_module:close()
  overhead_hint_module:remove_event()
end

function overhead_hint_module:add_overhand_hint(entity, order, ui_trans, distance, height)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  local guid = entity.Guid
  height = height or 0
  CsOverheadHintManagerUtil.AddOverheadHint(guid, order, ui_trans, height, overhead_hint_module.ui_offset_x, overhead_hint_module.ui_offset_y, distance)
end

function overhead_hint_module:add_overhand_hint_by_guid(guid, order, ui_trans, distance, height)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  height = height or 0
  CsOverheadHintManagerUtil.AddOverheadHint(guid, order, ui_trans, height, overhead_hint_module.ui_offset_x, overhead_hint_module.ui_offset_y, distance)
end

function overhead_hint_module:add_overhand_hint_reaction(entity, order, ui_trans, distance, offset_x, height)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  local guid = entity.Guid
  height = height or 0
  CsOverheadHintManagerUtil.AddOverheadHint(guid, order, ui_trans, height, offset_x, overhead_hint_module.ui_offset_y, distance)
end

function overhead_hint_module:add_overhand_hint_set_offset(entity, order, ui_trans, distance, offset_x, offset_y, height)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  local guid = entity.Guid
  height = height or 0
  CsOverheadHintManagerUtil.AddOverheadHint(guid, order, ui_trans, height, offset_x, offset_y, distance)
end

function overhead_hint_module:add_overhand_hint_set_offset_by_guid(guid, order, ui_trans, distance, offset_x, offset_y, height)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  height = height or 0
  if offset_x == nil then
    offset_x = overhead_hint_module.ui_offset_x
  end
  if offset_y == nil then
    offset_y = overhead_hint_module.ui_offset_y
  end
  CsOverheadHintManagerUtil.AddOverheadHint(guid, order, ui_trans, height, offset_x, offset_y, distance)
end

function overhead_hint_module:remove_overhand_hint(guid, order)
  if CsOverheadHintManagerUtil.IsNull() then
    return
  end
  CsOverheadHintManagerUtil.RemoveOverheadHint(guid, order)
end

function overhead_hint_module:reset_server_data()
  self._hide_hint_view_num = 0
end

function overhead_hint_module:clear_on_disconnect()
  overhead_hint_module:reset_server_data()
end

function overhead_hint_module:add_event()
  overhead_hint_module:remove_event()
  self._events = {}
  self._events[EventID.LuaSetLoadingState] = pack(self, overhead_hint_module._on_update_loading_state)
  self._events[EventID.OnCutscenePlaying] = pack(self, overhead_hint_module._on_cutscene_playing)
  self._events[EventID.LuaSetOverheadHintShowState] = pack(self, overhead_hint_module._on_set_overhead_hint_show_state)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function overhead_hint_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function overhead_hint_module:_on_update_loading_state(loading_state)
  self._is_loading = loading_state
  if loading_state then
    self._hide_hint_view_num = 0
  end
  overhead_hint_module:_refresh_hint_show_state()
end

function overhead_hint_module:_on_cutscene_playing(is_play)
  self._is_playing_cutscene = is_play
  overhead_hint_module:_refresh_hint_show_state()
end

function overhead_hint_module:_on_set_overhead_hint_show_state(is_show)
  if is_show then
    self._hide_hint_view_num = self._hide_hint_view_num - 1
  else
    self._hide_hint_view_num = self._hide_hint_view_num + 1
  end
  overhead_hint_module:_refresh_hint_show_state()
end

function overhead_hint_module:_refresh_hint_show_state()
  if self._hide_hint_view_num < 0 then
    self._hide_hint_view_num = 0
  end
  if self._hide_hint_view_num <= 0 and not self._is_playing_cutscene and not self._is_loading then
    if not CsOverheadHintManagerUtil.IsNull() then
      CsOverheadHintManagerUtil.ShowAllOverheadHint()
    end
    lua_event_module:send_event(lua_event_module.event_type.set_hint_show_state, true)
  else
    if not CsOverheadHintManagerUtil.IsNull() then
      CsOverheadHintManagerUtil.HideAllOverheadHint()
    end
    lua_event_module:send_event(lua_event_module.event_type.set_hint_show_state, false)
  end
end

overhead_hint_module.overhead_hint_order = {
  gentle_hint = 1,
  third_person_camera = 5,
  name = 20,
  reaction = 21,
  task = 30,
  time = 31,
  tracking = 32,
  pick_bubble = 40,
  bubble = 50,
  public_input_bubble = 60,
  chat_bubble = 70,
  function_building = 80,
  knock_bubble = 90,
  arrow = 100,
  capture_tip = 110,
  capture_emoji = 111,
  npc_favor_increase = 120
}
overhead_hint_module.ui_offset_y = 0
overhead_hint_module.ui_offset_x = 0
overhead_hint_module.bubble_type = {
  other = 0,
  emoji = 1,
  chat = 2,
  share = 3,
  demand = 4
}

function overhead_hint_module:init_arrow_hint_item(trans)
  local cls = {trans = trans}
  return cls
end

function overhead_hint_module:init_name_hint_item(trans)
  local cls = {
    trans = trans,
    text = UIUtil.find_text(trans, "content/NameBlock"),
    anim = UIUtil.find_animation(trans, "content/NpcDateAnim/HeartAnim")
  }
  return cls
end

function overhead_hint_module:set_name_hint_item(cls, txt_name)
  UIUtil.set_text(cls.text, txt_name)
end

function overhead_hint_module:init_task_hint_item(trans)
  local cls = {
    trans = trans,
    img_icon = UIUtil.find_image(trans, "content/img_icon"),
    trans_icon_bg = UIUtil.find_trans(trans, "content/img_bg")
  }
  return cls
end

function overhead_hint_module:set_task_hint_item(cls, task_data, is_authority, panel)
  do return end
  local icon_path
  local is_show_icon = is_authority
  if task_data ~= nil and is_show_icon then
    is_show_icon = task_data.taskStepCfg.type ~= task_module.step_task_type_move_to_point and task_data.TaskID ~= 40 and task_data.TaskID ~= 41 and task_data.TaskID ~= 42 and task_data.TaskID ~= 43 and task_data.TaskID ~= 44
    if is_show_icon then
      if task_data.taskStepCfg.stepid == 0 and task_data:isTaskComplete() then
        icon_path = "UISprite/Load/createrole/createrole_79"
      elseif task_data:isTaskComplete() then
        icon_path = "UISprite/Load/createrole/createrole_80"
      else
        icon_path = "UISprite/Load/createrole/createrole_81"
      end
    end
  end
  UIUtil.set_active(cls.trans, task_data ~= nil and is_show_icon)
  if task_data and is_show_icon then
    UIUtil.set_image(cls.img_icon, icon_path, panel:get_load_proxy())
    cls.img_icon:SetNativeSize()
  end
end

function overhead_hint_module:init_plant_hint_item(trans)
  local cls = {
    trans = trans,
    img_icon = UIUtil.find_image(trans, "content/img_icon")
  }
  return cls
end

function overhead_hint_module:set_plant_hint_item(cls, icon_path, panel)
  UIUtil.set_active(cls.trans, true)
  UIUtil.set_image(cls.img_icon, icon_path, panel:get_load_proxy())
end

function overhead_hint_module:init_npc_plant_hint_item(trans)
  local cls = {
    trans = trans,
    img_npc_icon = UIUtil.find_image(trans, "content/img_icon"),
    img_icon = UIUtil.find_image(trans, "content/img_icon2")
  }
  return cls
end

function overhead_hint_module:set_npc_plant_hint_item(cls, icon_path, npc_icon_path, panel)
  UIUtil.set_active(cls.trans, true)
  UIUtil.set_image(cls.img_npc_icon, npc_icon_path, panel:get_load_proxy())
  UIUtil.set_image(cls.img_icon, icon_path, panel:get_load_proxy())
end

function overhead_hint_module:init_bubble_hint_item(trans)
  local cls = {
    trans = trans,
    text = UIUtil.find_text(trans, "NameBlock"),
    anim = UIUtil.find_animation(trans, "NpcDateAnim/HeartAnim")
  }
  return cls
end

function overhead_hint_module:show_all_hint()
  self._hide_hint_view_num = 0
  overhead_hint_module:_refresh_hint_show_state()
end

function overhead_hint_module:hide_hint_by_orders(orders, is_white_list)
  local black_list
  if is_white_list then
    black_list = {}
    for _, order in pairs(overhead_hint_module.overhead_hint_order) do
      if not table.contains(orders, order) then
        table.insert(black_list, order)
      end
    end
  else
    black_list = orders or {}
  end
  if not CsOverheadHintManagerUtil.IsNull() then
    CsOverheadHintManagerUtil.SetOrderBlackList(black_list)
  end
end

function overhead_hint_module:show_hint_by_orders(orders, is_white_list)
  local black_list
  if is_white_list then
    black_list = {}
    for _, order in pairs(overhead_hint_module.overhead_hint_order) do
      if not table.contains(orders, order) then
        table.insert(black_list, order)
      end
    end
  else
    black_list = orders or {}
  end
  CsOverheadHintManagerUtil.RemoveOrderBlackList(black_list)
end

return overhead_hint_module
