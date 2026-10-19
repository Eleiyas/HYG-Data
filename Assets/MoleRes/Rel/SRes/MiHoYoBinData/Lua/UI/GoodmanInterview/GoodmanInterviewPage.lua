local M = G.Class("GoodmanInterviewPage", G.UIWindow)
local base = G.UIWindow
local INTERVIEW_PANEL_CLASS = "UI/Tracking/TrackingInterviewPanel"
local CHAT_INPUT_PANEL_CLASS = "UI/Chat/ChatInputFieldPanel"
local BAG_BUTTON_ITEM_CLASS = "UI/MainPage/EntrancePanelButtonItem"
local CHAT_TYPE_PUBLIC = 0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GoodmanInterview/GoodmanInterviewPage"
  self.config.type = EUIType.Page
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = false,
      camera = true,
      ability = false
    }
  }
  self._interview_panel = nil
  self._chat_input_panel = nil
  self._bag_button = nil
end

function M:on_create()
  base.on_create(self)
  self._interview_panel = self:add_panel(INTERVIEW_PANEL_CLASS, self._interview_content)
  self._chat_input_panel = self:add_panel(CHAT_INPUT_PANEL_CLASS, self._input_field_main_chat)
  self._chat_input_panel:set_reaction_single_person_only(true)
  self:_setup_bag_button()
  self:_setup_take_back_buttons()
  self:add_lua_listener(lua_event_module.event_type.on_reaction_dialog_close_and_open, pack(self, M._on_reaction_dialog_toggled))
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.ChangeUIControlMode, pack(self, M._on_ui_ctrl_mode_change))
  self:add_evt_listener(EventID.LuaOnPlayerEquipRsp, pack(self, M._on_player_equip_rsp))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Enter, function()
    if not self._chat_input_panel then
      return
    end
    if not self._chat_input_panel:is_input_focused() then
      self._chat_input_panel:on_chat_input_select()
      return
    end
    self._chat_input_panel:on_enter_click()
  end)
  self:bind_input_and_fun(ActionType.Act.RetrieveKey, function()
    if self:_is_chat_input_focused() or not self:_can_take_back() then
      return
    end
    self:_on_take_back_click()
  end)
end

function M:_is_chat_input_focused()
  return self._chat_input_panel ~= nil and self._chat_input_panel:is_input_focused()
end

function M:on_enable()
  base.on_enable(self)
  self._chat_input_panel:show(CHAT_TYPE_PUBLIC)
  self._chat_input_panel:set_chat_type(CHAT_TYPE_PUBLIC)
  self._bag_button:check_unlock_anim()
  self:_refresh_take_back_buttons()
end

function M:_setup_bag_button()
  self._bag_button = self:add_panel(BAG_BUTTON_ITEM_CLASS, self._bag_button_node)
  local cfg = LocalDataUtil.get_value(typeof(EntranceHUDButtonCfg), FunctionEntranceType.Bag)
  self._bag_button:refresh(cfg)
  self:bind_callback(self._bag_button:get_btn(), pack(self, M._on_bag_click))
  local bag_action = self._bag_button:get_input_action()
  if bag_action then
    self:bind_input_and_fun(bag_action, function()
      if self:_is_chat_input_focused() then
        return
      end
      self:_on_bag_click()
    end)
  end
end

function M:_on_bag_click()
  back_bag_module:try_open_bag_entrance()
end

function M:_setup_take_back_buttons()
  if not_null(self._take_back_tip_btn) then
    self:bind_callback(self._take_back_tip_btn, pack(self, M._on_take_back_click))
  end
  if not_null(self._take_back_btn) then
    self:bind_callback(self._take_back_btn, pack(self, M._on_take_back_click))
  end
  self:_refresh_take_back_buttons()
end

function M:_on_take_back_click()
  local guid = player_module:get_player_guid()
  CsGameplayUtilitiesExhibitionUtil.SendTakeBackEvent(guid)
  local cur_tool = player_module:get_cur_equip_item()
  if cur_tool and cur_tool.MakeGUID and cur_tool.MakeGUID > 0 then
    CsToolUtil.UnequipToolSpecificByMakeGuid(guid, cur_tool.MakeGUID)
  end
end

function M:_can_take_back()
  if player_controller_module:is_ctrl_ui_item_active(PlayerCtrlUIItem.TakeBackItem) then
    return true
  end
  local cur_tool = player_module:get_cur_equip_item()
  return cur_tool ~= nil and cur_tool.MakeGUID ~= nil and cur_tool.MakeGUID > 0
end

function M:_refresh_take_back_buttons()
  local active = self:_can_take_back()
  if not_null(self._take_back_tip_node) then
    UIUtil.set_active(self._take_back_tip_node, active)
  end
  if not_null(self._take_back_btn_node) then
    UIUtil.set_active(self._take_back_btn_node, active)
  end
end

function M:_on_ui_ctrl_mode_change()
  self:_refresh_take_back_buttons()
end

function M:_on_player_equip_rsp()
  self:_refresh_take_back_buttons()
end

function M:_on_reaction_dialog_toggled(active)
  self._chat_input_panel:set_chat_panel_all_active(active)
end

return M
