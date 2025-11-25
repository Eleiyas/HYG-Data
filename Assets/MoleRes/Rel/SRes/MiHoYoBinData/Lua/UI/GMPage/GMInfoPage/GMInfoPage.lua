local M = G.Class("GMInfoPage", G.UIWindow)
local base = G.UIWindow
local tick_interval = 0.5
local item_cls = "UI/GMPage/GMInfoPage/GMInfoItem"

local function internal_pack(self, func, ...)
  assert(self == nil or type(self) == "table")
  assert(func ~= nil and type(func) == "function")
  return function(...)
    return func(self, ...)
  end
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GM/GMInfoPage"
  self.config.type = EUIType.Top
  self.config.input_penetrate = true
  self._is_close = false
  self._tick_timer = 0
  self.config.handle_input = true
  self._player_guids = {}
  self.items = {}
  self.item_cache = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
  local item = self:add_panel(item_cls, self._info_item_obj)
  table.insert(self.item_cache, item)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  UIUtil.set_active(self._tip_root, true)
  UIUtil.set_active(self._tip_root2, true)
  CsCoroutineManagerUtil.Invoke(3, function()
    if self.is_active then
      UIUtil.set_active(self._tip_root, false)
      UIUtil.set_active(self._tip_root2, false)
    end
  end)
  self:_add_item("WorldID", internal_pack(self, M._get_world_id), true)
  self:_add_item("Galaxy", internal_pack(self, M._get_galaxy), true)
  self:_add_item("玩家坐标", internal_pack(self, M._get_player_pos), false)
  self:_add_item("前方物体（待修复）", internal_pack(self, M._get_forward_item), false)
  self:_add_item("Player信息", internal_pack(self, M._players_to_text), false)
  self:_add_item("UI界面栈", internal_pack(self, M._get_ui_stack), false)
  self:_add_item("UIOpening界面", internal_pack(self, M._get_opening_page), false)
  self:_add_item("UIClosing界面", internal_pack(self, M._get_closing_page), false)
  self:_add_item("界面输入栈", internal_pack(self, M._get_input_action_stack_page), false)
  self:_add_item("当前输入锁", internal_pack(self, M._get_input_lock), false)
  self:_add_item("当前UI输入模式", internal_pack(self, M._get_cur_ui_mode), false)
  self:_add_item("当前操控模式", internal_pack(self, M._get_cur_ctrl_mode), false)
  self:_add_item("HYG 宏定义", internal_pack(self, M._get_hyg_macro_def), false)
  self:_add_item("表演准备状态", internal_pack(self, M._get_performance_standby_state), false)
  self:_add_item("当前网络白名单", internal_pack(self, M._get_net_white_packet_id_list), false)
  self:_add_item("当前网络黑名单", internal_pack(self, M._get_net_black_packet_id_list), false)
end

function M:on_disable()
  base.on_disable(self)
  for i, v in ipairs(self.items) do
    table.insert(self.item_cache, v)
    v:set_active(false)
  end
end

function M:update(deltaTime)
  if not self.is_active then
    return
  end
  base.update(self, deltaTime)
  if self.is_active then
    self._tick_timer = self._tick_timer - deltaTime
    if self._tick_timer <= 0 then
      self._tick_timer = tick_interval
    end
  end
  self:rebuild_layout()
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  
  local function create_wrapper(func, num)
    local function f()
      func(self, num)
    end
    
    return f
  end
  
  self:bind_input_and_fun(ActionType.Act.Numpad0, create_wrapper(self._handle_numpad_down, 0), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad1, create_wrapper(self._handle_numpad_down, 1), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad2, create_wrapper(self._handle_numpad_down, 2), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad3, create_wrapper(self._handle_numpad_down, 3), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad4, create_wrapper(self._handle_numpad_down, 4), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad5, create_wrapper(self._handle_numpad_down, 5), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad6, create_wrapper(self._handle_numpad_down, 6), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad7, create_wrapper(self._handle_numpad_down, 7), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad8, create_wrapper(self._handle_numpad_down, 8), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Numpad9, create_wrapper(self._handle_numpad_down, 9), ActionType.EType.ButtonPressed)
end

function M:_add_btn_listener()
  self:bind_callback(self._close_btn, function()
    self:_on_btn_close_click()
  end)
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  UIManagerInstance:close(self.guid)
end

function M:_add_item(title, get_text_func, refresh_per_frame)
  local item = self:_get_item()
  if item then
    item:init_data(title, get_text_func, refresh_per_frame)
    item:set_active(true)
    table.insert(self.items, item)
  end
end

function M:_get_item()
  if self.item_cache and #self.item_cache > 0 then
    local item = self.item_cache[1]
    table.remove(self.item_cache, 1)
    return item
  end
  local obj = UIUtil.load_prefab_set_parent(self._info_item_obj, self._gm_info_root_trans)
  local item = self:add_panel(item_cls, obj)
  return item
end

function M:_get_local_player()
  if CsEntityManagerUtil.avatarManager == nil then
    return nil
  else
    return CsEntityManagerUtil.avatarManager:GetPlayer()
  end
end

function M:_get_remote_players()
  if CsEntityManagerUtil.avatarManager == nil then
    return {}
  else
    return CsEntityManagerUtil.avatarManager:GetOtherPlayers()
  end
end

function M:_add_player(player)
  if player ~= nil then
    table.insert(self._player_guids, player.guid)
  end
end

function M:_add_players(players)
  for _, player in pairs(players) do
    self:_add_player(player)
  end
end

function M:_clear_players()
  self._player_guids = {}
end

function M:_handle_numpad_down(num)
  local player_guid = self._player_guids[num + 1]
  local player = CsEntityManagerUtil.GetEntityByGuid(player_guid)
  if player ~= nil then
    UIUtil.show_tips(string.format("已向服务器发送将%s设置为场景主机的请求", player.DisplayName))
    local content = "setAuthority " .. MultiplayerUtility.GetEntityAuthorityUID(player)
    local msg = CS.Proto.GMCmdReq()
    msg.CmdData = content
    NetHandlerIns:send_msg(msg)
  end
end

function M:_get_world_id()
  local scene_id = level_module:get_cur_scene_id()
  return tostring(scene_id)
end

function M:_get_galaxy()
  return tostring(CsGameplayUtilitiesGalaxyUtil.GetSelectedGalaxyType())
end

function M:_get_player_pos()
  return GMDefaultValueFun:get_player_pos()
end

function M:_get_forward_item()
  return "无"
end

function M:_players_to_text()
  local player_guids = self._player_guids
  if player_guids == nil or #player_guids == 0 then
    return ""
  end
  local text_parts = {}
  local player_count = 0
  for _, v in pairs(player_guids) do
    local player = CsEntityManagerUtil.GetEntityByGuid(v)
    if player ~= nil then
      table.insert(text_parts, string.format("Player%d: %s", player_count, player.DisplayName))
      player_count = player_count + 1
    end
  end
  local result = table.concat(text_parts, "\n")
  return result
end

function M:_get_ui_stack()
  local stack_str = ""
  if UIManagerInstance then
    for i, v in ipairs(UIManagerInstance._window_stack or {}) do
      stack_str = stack_str .. "|" .. v.__cname
    end
  end
  return stack_str
end

function M:_get_opening_page()
  local str = ""
  if UIManagerInstance then
    for i, v in ipairs(UIManagerInstance._opening_windows or {}) do
      str = str .. "|" .. v.__cname
    end
  end
  return str
end

function M:_get_closing_page()
  local str = ""
  if UIManagerInstance then
    for i, v in ipairs(UIManagerInstance._closing_windows or {}) do
      str = str .. "|" .. v.__cname
    end
  end
  return str
end

function M:_get_input_action_stack_page()
  local str = ""
  local index = 1
  if UIManagerInstance then
    for i = EUIInputStackLevel.high, EUIInputStackLevel.low do
      local stack = UIManagerInstance._window_input_action_stack[i]
      if 0 < #stack then
        for i = #stack, 1, -1 do
          str = str .. "|" .. tostring(index) .. "->" .. stack[i].__cname
          index = index + 1
        end
      end
    end
  end
  return str
end

local input_lock_name = {
  "Common",
  "UIOpenAndClose",
  "DelayLock"
}

function M:_get_input_lock()
  local str = ""
  if InputManagerIns then
    local bit = InputManagerIns._lock_bit
    for i = 0, 10 do
      if bit & 1 << i ~= 0 then
        if input_lock_name[i + 1] then
          str = str .. "|" .. input_lock_name[i + 1]
        else
          str = str .. "|" .. tostring(i)
        end
      end
    end
  end
  return str
end

function M:_get_cur_ui_mode()
  local str = ""
  if player_controller_module then
    str = "上一个：" .. tostring(player_controller_module._last_ui_ctrl_mode) .. "\n"
    str = str .. "当前：" .. tostring(player_controller_module._cur_ui_ctrl_mode)
  end
  return str
end

function M:_get_cur_ctrl_mode()
  local str = ""
  if CsInputManagerUtil then
    str = tostring(CsInputManagerUtil.curCtrlModeType)
  end
  return str
end

function M:_get_hyg_macro_def()
  local str = ""
  if ApplicationUtil then
    str = tostring(ApplicationUtil.GetHygMacroDef())
  end
  return str
end

function M:_get_performance_standby_state()
  local str = ""
  if CsPerformanceManagerUtil then
    str = tostring(CsPerformanceManagerUtil.StandbyState)
  end
  return str
end

function M:_get_net_black_packet_id_list()
  local str = "Cmd Ids : "
  local list = GM_CSharp.NetPacketBlackList
  if list and list.Count > 0 then
    for i = 0, list.Count - 1 do
      local id = list[i]
      str = str .. tostring(id) .. " "
    end
  end
  return str
end

function M:_get_net_white_packet_id_list()
  local str = "Cmd Ids : "
  local list = GM_CSharp.NetPacketWhiteList
  if list and list.Count > 0 then
    for i = 0, list.Count - 1 do
      local id = list[i]
      str = str .. tostring(id) .. " "
    end
  end
  return str
end

function M:rebuild_layout()
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._gm_info_root_trans)
end

return M
