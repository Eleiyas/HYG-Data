local M = G.Class("MenuWheelPanel", G.UIPanel)
local base = G.UIPanel
local MenuWheelItem = require("UI/MainPage/MenuWheelItem")
local EntrancePanel = require("UI/MainPage/EntrancePanel")
require("UI/MainPage/MenuWheelCfg")
local BUTTON_TEXT_NODE = "text"
local SHORT_CUT_TIPS_ICON = "UISprite/Load/Common/ShortCut/Handle/handle_18.png"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/Joystick_WheelPanel"
  self._is_showing = false
  self._has_notified_self_hide = false
  self._pending_show_entrance_on_hide = false
  self._is_hide_close_listener = false
  self._display_entries = {}
  self._item_objs = {}
  self._place_holder_objs = {}
  self._item_callbacks = {}
  self._cur_select_index = 0
  self._button_slots = {}
  self._button_entries = {}
end

function M:on_create()
  base.on_create(self)
  local short_cut_tips = UIUtil.get_text_by_id("UI_JoystickWheel_ChooseSystem", SHORT_CUT_TIPS_ICON)
  UIUtil.set_text_with_dynamic_sprite(self._txt_short_cut_tips, short_cut_tips, nil)
  self:_set_wheel_visible(false)
  self._common_btn_cfgs = LocalDataUtil.get_table(typeof(EntranceHUDButtonCfg))
  self:_add_btn_listener()
  self._btn_callback_map = EntrancePanel.get_btn_callback_map()
  self._btn_redpoint_map = EntrancePanel.get_btn_redpoint_map()
end

function M:update(deltaTime)
  if self._is_showing then
    self:_update_gamepad_stick()
  end
end

function M:on_enable()
  base.on_enable(self)
  if not self._is_showing then
    self:_set_wheel_visible(false)
  end
end

function M:on_disable()
  base.on_disable(self)
  if self._is_showing then
    self:_hide_menu_wheel()
  else
    self:_reset_hidden_state()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_menu_wheel_down, pack(self, M._handle_menu_down))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.MenuWheel, M._handle_menu_up)
  self:bind_input_and_fun(ActionType.Act.MenuWheel, M._handle_menu_up, ActionType.EType.ButtonReleased)
  self:_build_button_slots()
  for _, slot in ipairs(self._button_slots) do
    self:bind_input_and_btn(slot.action, slot.btn, ActionType.EType.ButtonReleased)
  end
  self:bind_input_and_fun(ActionType.Act.ToolWheel, function()
    return self._is_showing == true
  end)
end

function M:_build_button_slots()
  self._button_slots = {
    {
      key = "dpad_up",
      action = ActionType.Act.DPad_Up,
      btn = self._btn_online
    },
    {
      key = "dpad_down",
      action = ActionType.Act.DPad_Down,
      btn = self._btn_invite
    },
    {
      key = "north",
      action = ActionType.Act.ButtonNorth,
      btn = self._btn_appearance
    },
    {
      key = "south",
      action = ActionType.Act.ButtonSouth,
      btn = self._btn_exit
    },
    {
      key = "west",
      action = ActionType.Act.ButtonWest,
      btn = self._btn_map
    },
    {
      key = "east",
      action = ActionType.Act.ButtonEast,
      btn = self._btn_eat
    }
  }
  for _, slot in ipairs(self._button_slots) do
    if is_null(slot.btn) then
      slot.btn = nil
    else
      slot.img = UIUtil.find_image(slot.btn, nil)
      slot.txt = UIUtil.find_text(slot.btn.transform, BUTTON_TEXT_NODE)
      if not is_null(slot.img) then
        slot.def_sprite = slot.img.sprite
      end
      if not is_null(slot.txt) then
        slot.def_text = slot.txt.text
      end
    end
  end
end

function M:_add_btn_listener()
  for _, slot in ipairs(self._button_slots) do
    if slot.btn ~= nil then
      self:bind_callback(slot.btn, function()
        self:_on_button_click(slot)
      end)
    end
  end
end

function M:_refresh_button_entries()
  self._button_entries = {}
  local cfgs = menu_wheel_module.MENU_WHEEL_BUTTON_ENTRIES
  for _, slot in ipairs(self._button_slots) do
    local entries = cfgs[slot.action]
    local entry
    if entries ~= nil then
      for _, cfg_entry in ipairs(entries) do
        if self:_is_entry_available(cfg_entry) then
          entry = cfg_entry
          break
        end
      end
      if entry ~= nil and slot.btn == nil then
        Logger.LogError(string.format("[MenuWheel] 按键槽位 %s 在prefab上没有节点，配置项 %s 不生效", slot.key, tostring(entry.key)))
        entry = nil
      end
    end
    self._button_entries[slot.action] = entry
  end
end

function M:_refresh_button_ui()
  for _, slot in ipairs(self._button_slots) do
    if slot.btn ~= nil then
      local entry = self._button_entries[slot.action]
      UIUtil.set_active(slot.btn.gameObject, entry ~= nil)
      if entry ~= nil then
        self:_set_button_icon(slot, entry)
        self:_set_button_name(slot, entry)
      end
    end
  end
end

function M:_set_button_icon(slot, entry)
  if is_null(slot.img) then
    return
  end
  local icon = self:_get_entry_icon_path(entry)
  if string.is_valid(icon) then
    UIUtil.set_image(slot.img, icon, self:get_load_proxy())
  elseif not is_null(slot.def_sprite) then
    UIUtil.set_image(slot.img, slot.def_sprite)
  end
end

function M:_set_button_name(slot, entry)
  if is_null(slot.txt) then
    return
  end
  local name = self:_get_entry_display_name(entry)
  if name == nil or name == "" then
    name = slot.def_text
  end
  if name ~= nil then
    UIUtil.set_text(slot.txt, name)
  end
end

function M:_on_button_click(slot)
  local entry = self._button_entries[slot.action]
  self:_hide_menu_wheel()
  self:_open_entry(entry)
end

function M:_is_entry_unlocked(entry)
  if entry.is_unlocked then
    return entry.is_unlocked() == true
  end
  if entry.entrance_type ~= nil then
    local cfg = self._common_btn_cfgs and self._common_btn_cfgs[entry.entrance_type]
    return cfg ~= nil and cfg.IsShow
  end
  return true
end

function M:_is_entry_available(entry)
  if not self:_is_entry_unlocked(entry) then
    return false
  end
  return menu_wheel_module:is_entry_scene_matched(entry)
end

function M:_open_entry(entry)
  if entry == nil or entry.is_placeholder then
    return
  end
  if entry.open then
    if not can_enter_function_entrance(entry.entrance_id, false) then
      return
    end
    entry.open(self)
  end
  if entry.entrance_type ~= nil and self._btn_callback_map then
    local func_name = self._btn_callback_map[entry.entrance_type]
    if func_name then
      local entrance_panel = self.holder:get_panel(MainPanelType.EntranceButton)
      if entrance_panel == nil or entrance_panel[func_name] == nil then
        Logger.LogError(string.format("[MenuWheel] 入口 %s 的回调 %s 在EntrancePanel上不存在", tostring(entry.key), tostring(func_name)))
        return
      end
      if can_enter_function_entrance(entry.entrance_type, true) then
        entrance_panel[func_name](entrance_panel)
      end
      return
    end
  end
end

function M:_get_entry_redpoint_func(entry)
  if entry == nil or entry.is_placeholder then
    return nil
  end
  if entry.red_point then
    return function(rp)
      rp:ShowRedPoint(entry.red_point() or RedPointType.None)
    end
  end
  if entry.entrance_type ~= nil and self._btn_redpoint_map then
    local func = self._btn_redpoint_map[entry.entrance_type]
    if func then
      return func
    end
  end
  return nil
end

function M:_refresh_display_entries()
  self._cur_select_index = 0
  self._display_entries = {}
  for _, entry in ipairs(menu_wheel_module.MENU_WHEEL_ENTRIES) do
    if entry.is_placeholder or self:_is_entry_available(entry) then
      table.insert(self._display_entries, entry)
    end
  end
end

function M:_refresh_wheel_ui()
  UIUtil.set_active(self._obj_cell_wheel, false)
  local count = #self._display_entries
  if count > menu_wheel_module.MENU_WHEEL_ITEM_NUM then
    Logger.LogError("[MenuWheel] _display_entries配置错误")
    return
  end
  for i, entry in ipairs(self._display_entries) do
    local cls = self._item_objs[i]
    if cls == nil then
      cls = MenuWheelItem.create(self._obj_cell_wheel, self._rect_tools_parent, self, self._item_callbacks)
      self._item_objs[i] = cls
    end
    UIUtil.set_active(cls.trans, true)
    if self._place_holder_objs[i] then
      UIUtil.set_active(self._place_holder_objs[i].trans, false)
    end
    cls:set_slot(i, menu_wheel_module.MENU_WHEEL_ITEM_NUM)
    cls:set_data(i, entry, i == self._cur_select_index, self:_get_entry_icon_path(entry), self:_get_entry_redpoint_func(entry))
  end
  for i = count + 1, #self._item_objs do
    UIUtil.set_active(self._item_objs[i].trans, false)
  end
  for i = count + 1, menu_wheel_module.MENU_WHEEL_ITEM_NUM do
    local cls = self._place_holder_objs[i]
    local entry = menu_wheel_module.PLACE_HOLDER_ENTRY
    if cls == nil then
      cls = MenuWheelItem.create(self._obj_cell_wheel, self._rect_tools_parent, self, self._item_callbacks)
      self._place_holder_objs[i] = cls
    end
    UIUtil.set_active(cls.trans, true)
    cls:set_slot(i, menu_wheel_module.MENU_WHEEL_ITEM_NUM)
    cls:set_data(i, entry, i == self._cur_select_index, self:_get_entry_icon_path(entry), self:_get_entry_redpoint_func(entry))
  end
  self:_set_select_txt()
end

function M:_update_gamepad_stick()
  local all_count = menu_wheel_module.MENU_WHEEL_ITEM_NUM
  if all_count <= 0 then
    return
  end
  local stick_x, stick_y = InputManagerIns:get_vector2(ActionType.Act.RightStick)
  if not stick_x or not stick_y then
    UIUtil.set_active(self._rect_follow_mouse, false)
    self:_set_wheel_index(0)
    return
  end
  local magnitude = math.sqrt(stick_x * stick_x + stick_y * stick_y)
  if magnitude < menu_wheel_module.GAMEPAD_STICK_DEADZONE then
    UIUtil.set_active(self._rect_follow_mouse, false)
    if self._cur_select_index ~= 0 then
      local entry = self._display_entries[self._cur_select_index]
      self:_hide_menu_wheel()
      self:_open_entry(entry)
    end
    return
  end
  UIUtil.set_active(self._rect_follow_mouse, true)
  local angle_rad = math.atan(stick_x, stick_y)
  local angle_deg = math.deg(angle_rad)
  if angle_deg < 0 then
    angle_deg = angle_deg + 360
  end
  self._rect_follow_mouse.localEulerAngles = Vector3(0, 0, -angle_deg)
  local sector = 360 / all_count
  local rota_z = (angle_deg + sector / 2) % 360
  local index = math.floor(rota_z / sector) - menu_wheel_module.INDEX_START_OFFSET + 1
  self:_set_wheel_index((index - 1) % menu_wheel_module.MENU_WHEEL_ITEM_NUM + 1)
end

function M:_set_wheel_index(index)
  local entry = self._display_entries[index]
  if entry and entry.is_placeholder then
    index = 0
  end
  if self._cur_select_index == index then
    return
  end
  local last_cls = self._item_objs[self._cur_select_index]
  if last_cls then
    last_cls:set_selected(false)
  end
  self._cur_select_index = index
  local cls = self._item_objs[index]
  if cls then
    cls:set_selected(true)
  end
  self:_set_select_txt()
end

function M:_get_entry_icon_path(entry)
  if entry == nil or entry.is_placeholder then
    return nil
  end
  if entry.icon_override then
    local icon = entry.icon_override()
    if string.is_valid(icon) then
      return icon
    end
  end
  if entry.icon and string.is_valid(entry.icon) then
    return entry.icon
  end
  if entry.entrance_type ~= nil then
    local cfg = self._common_btn_cfgs and self._common_btn_cfgs[entry.entrance_type]
    if cfg and string.is_valid(cfg.buttonIcon) then
      return cfg.buttonIcon
    end
  end
  return nil
end

function M:_get_entry_display_name(entry)
  if entry == nil or entry.is_placeholder then
    return ""
  end
  if entry.name_override then
    local name = entry.name_override()
    if name ~= nil then
      return name
    end
  end
  if entry.entrance_type ~= nil then
    local cfg = self._common_btn_cfgs and self._common_btn_cfgs[entry.entrance_type]
    if cfg then
      return cfg.buttonName
    end
  end
  if string.is_valid(entry.name_text_id) then
    return UIUtil.get_text_by_id(entry.name_text_id)
  end
  return ""
end

function M:_set_select_txt()
  local entry = self._display_entries[self._cur_select_index]
  UIUtil.set_text(self._txt_equip_name, self:_get_entry_display_name(entry))
end

function M:_handle_menu_down(action)
  if self._is_showing then
    return
  end
  if not player_module:ui_default_validate_player_states() then
    menu_wheel_module:log_mw("menu_down rejected: player_states_invalid")
    return
  end
  self:_show_menu_wheel()
end

function M:_handle_menu_up(action)
  if not self._is_showing then
    return
  end
  self:_hide_menu_wheel()
end

function M:_show_menu_wheel()
  self._is_showing = true
  self:set_last_sibling()
  self:change_state(EUIState.Show)
  self:_set_wheel_visible(true)
  self:_refresh_display_entries()
  self:_refresh_wheel_ui()
  self:_refresh_button_entries()
  self:_refresh_button_ui()
  self.config.input_lock_type = input_lock_type.lock_buttons | input_lock_type.lock_right_axis
  self:_on_self_show()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if is_null(self.game_obj) or not self._is_showing then
      return
    end
    self.holder:set_player_ctrl_cfg(true, false, false)
  end)
end

function M:_hide_menu_wheel()
  self._is_showing = false
  self:change_state(EUIState.Hide)
  self:_reset_hidden_state()
  self:_on_self_hide()
end

function M:_reset_hidden_state()
  self:_set_wheel_visible(false)
  self.config.input_penetrate = true
  InputManagerIns:unlock_3C(self)
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  self:_reset_hidden_state()
  self.holder:refresh_ability_availability()
end

function M:_set_wheel_visible(visible)
  if is_null(self._trans_middle) then
    return
  end
  UIUtil.set_active(self._trans_middle, visible)
end

function M:_on_self_show()
  self._has_notified_self_hide = false
  self._pending_show_entrance_on_hide = false
  lua_event_module:send_event(lua_event_module.event_type.on_menu_wheel_state_change, true)
  self.holder:enter_hud_solo_mode()
end

function M:_on_self_hide()
  if self._has_notified_self_hide then
    return
  end
  self._has_notified_self_hide = true
  self._pending_show_entrance_on_hide = true
  lua_event_module:send_event(lua_event_module.event_type.on_menu_wheel_state_change, false)
  self.holder:exit_hud_solo_mode()
end

function M:is_showing()
  return self._is_showing
end

function M:set_last_sibling()
  self.trans:SetAsLastSibling()
end

return M
