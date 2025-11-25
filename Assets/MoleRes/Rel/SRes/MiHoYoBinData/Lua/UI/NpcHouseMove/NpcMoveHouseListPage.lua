local M = G.Class("NpcMoveHouseListPage", G.UIWindow)
local base = G.UIWindow
local npc_move_house_list_entry_class_name = "UI/NpcHouseMove/NpcMoveHouseListEntry"
local NpcMoveHouseUtil = require("UI/NpcHouseMove/NpcMoveHouseUtil")

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcHouseMove/NpcMoveHouseListPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._panel_list = {}
end

function M:refresh_panel(parent_page)
  self._parent_page = parent_page
  self._toggle_list = {}
  self:_refresh_housemove_scroller()
  local toggle = self._toggle_list[1]
  if toggle then
    toggle.isOn = false
    toggle.isOn = true
  end
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M.on_btn_close_clicked))
  self:bind_callback(self._btn_movein, pack(self, M.on_btn_movein_clicked))
  self:bind_callback(self._btn_moveout, pack(self, M.on_btn_moveout_clicked))
  self:bind_callback(self._btn_cancel_moveouttomorrow, pack(self, M._show_cancel_move_popup))
  self:bind_callback(self._btn_cancel_moveintomorrow, pack(self, M._show_cancel_move_popup))
  self:bind_callback(self._btn_location, function()
    NpcMoveHouseUtil.open_map_and_locate_npc_house(self._selected_npc_id)
  end)
end

function M:_show_cancel_move_popup()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Cancel_Moving_NpcHouseMove_Dialog_ConfirmWithdraw"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:_cancel_move()
  end)
  popup:show()
end

function M:_cancel_move()
  local move_data = CsNpcInvitationModuleUtil.GetMoveDataByNpcId(self._selected_npc_id)
  if move_data then
    CsNpcInvitationModuleUtil.SendCancelChangeNpcResidentsReq(move_data.MoveOutNpcId, move_data.MoveInNpcId)
  end
end

function M:on_btn_close_clicked()
  self._parent_page:on_list_panel_return()
end

function M:on_btn_movein_clicked()
  if CsNpcInvitationModuleUtil.GetMovingNpcCount() >= NpcMoveHouseUtil.get_move_in_out_limit() then
    UIUtil.show_tips_by_text_id("NpcHouseMove_LimitReached")
  else
    self._parent_page:set_edit_panel_active(0, true)
  end
end

function M:on_btn_moveout_clicked()
  if CsNpcInvitationModuleUtil.GetMovingNpcCount() >= NpcMoveHouseUtil.get_move_in_out_limit() then
    UIUtil.show_tips_by_text_id("NpcHouseMove_LimitReached")
  else
    self._parent_page:set_edit_panel_active(self._selected_npc_id, false)
  end
end

function M:_refresh_housemove_scroller()
  self._npc_invitation_data_list = list_to_table(CsNpcInvitationModuleUtil.GetListPageDisplayInvitationData())
  self._scroller_movehouse:Init(pack(self, M._refresh_entry), NpcMoveHouseUtil.get_resident_limit())
end

function M:_refresh_entry(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local panel = self._panel_list[instance_id]
  if is_null(panel) then
    panel = self:add_panel(npc_move_house_list_entry_class_name, trans)
    self._panel_list[instance_id] = panel
  end
  local invitation_data = self._npc_invitation_data_list[index]
  panel:set_data(invitation_data, false)
  local toggle = panel:get_toggle()
  toggle.group = self._toggle_group
  local npc_id, npc_cfg, npc_house_cfg
  if invitation_data then
    npc_id = invitation_data.NpcId
    npc_cfg, npc_house_cfg = NpcMoveHouseUtil.get_npc_data(npc_id)
  end
  self:bind_callback(toggle, function(is_on)
    if is_on then
      self._selected_npc_id = npc_id
      self:_refresh_npc_info_panel(invitation_data, npc_cfg, npc_house_cfg)
    end
  end)
  self._toggle_list[index] = toggle
end

function M:_refresh_npc_info_panel(invitation_data, npc_cfg, npc_house_cfg)
  local move_data
  if npc_cfg then
    local npc_id = npc_cfg.id
    move_data = CsNpcInvitationModuleUtil.GetMoveDataByNpcId(npc_id)
    if move_data and move_data.MoveOutNpcId == 0 then
      self:_set_as_empty_npc_info_panel()
    else
      self:_set_as_npc_info_panel(npc_cfg, npc_house_cfg)
    end
  else
    self:_set_as_empty_npc_info_panel()
  end
  self:_refresh_bottom_button(invitation_data, npc_cfg, move_data)
end

function M:_set_as_empty_npc_info_panel()
  UIUtil.set_active(self._trans_npcinfo, false)
  UIUtil.set_active(self._trans_emptynpcinfo, true)
  UIUtil.set_active(self._trans_moveouttomorrow, false)
  UIUtil.set_active(self._trans_cd, false)
  if self._selected_npc_id then
    local move_data = CsNpcInvitationModuleUtil.GetMoveDataByNpcId(self._selected_npc_id)
    if move_data then
      if not CsNpcInvitationModuleUtil.HasNpcHouseAreaSelected(self._selected_npc_id) then
        UIUtil.set_text_by_id(self._txt_move_tips, "NpcHouseMove_SelectHouseLocation")
      else
        UIUtil.set_text_by_id(self._txt_move_tips, "NpcHouseMove_FriendMovingIn")
      end
    else
      UIUtil.set_text_by_id(self._txt_move_tips, "NpcHouseMove_SelectFriend")
    end
  else
    UIUtil.set_text_by_id(self._txt_move_tips, "NpcHouseMove_SelectFriend")
  end
end

function M:_set_as_npc_info_panel(npc_cfg, npc_house_cfg)
  UIUtil.set_active(self._trans_npcinfo, true)
  UIUtil.set_active(self._trans_emptynpcinfo, false)
  UIUtil.set_active(self._trans_btn_movein, false)
  UIUtil.set_image(self._img_npcicon, npc_cfg.iconnamesmall, self:get_load_proxy())
  if npc_house_cfg then
    UIUtil.set_image(self._img_houseicon, npc_house_cfg.icon, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_npcname, npc_cfg.name)
end

function M:_refresh_bottom_button(invitation_data, npc_cfg, move_data)
  UIUtil.set_active(self._trans_btn_movein, false)
  UIUtil.set_active(self._trans_btn_moveout, false)
  UIUtil.set_active(self._trans_moveintomorrow, false)
  UIUtil.set_active(self._trans_moveouttomorrow, false)
  UIUtil.set_active(self._trans_cd, false)
  if npc_cfg then
    if move_data then
      if move_data.MoveInNpcId == 0 then
        UIUtil.set_active(self._trans_moveouttomorrow, true)
      elseif move_data.MoveOutNpcId == 0 then
        self:set_and_activate_moveintomorrow_btn(move_data.MoveInNpcId)
      else
        self:set_and_activate_moveintomorrow_btn(move_data.MoveInNpcId)
      end
    else
      local remaining_cooldown_days = 0
      if invitation_data.AvailabilityInfo.ResidentMove then
        local nowtime = CsServerTimeModuleUtil.ServerUtcNowTimeStamp()
        remaining_cooldown_days = math.ceil((invitation_data.AvailabilityInfo.ResidentMove.MoveOutCoolDownTime - nowtime) / 86400)
      end
      if 0 < remaining_cooldown_days then
        UIUtil.set_active(self._trans_cd, true)
        UIUtil.set_text_by_id(self._txt_cd, "NpcHouseMoveOut_Cooldown", remaining_cooldown_days)
      else
        UIUtil.set_active(self._trans_btn_moveout, true)
      end
    end
  else
    UIUtil.set_active(self._trans_btn_movein, true)
  end
end

function M:set_and_activate_moveintomorrow_btn(npc_id)
  UIUtil.set_active(self._trans_moveintomorrow, true)
  local npc_cfg = LocalDataUtil.get_value(typeof(CS.BNpcCfg), npc_id)
  UIUtil.set_text(self._txt_moveintomorrow_npcname, npc_cfg.name)
  UIUtil.set_image(self._img_moveintomorrow_npcicon, npc_cfg.iconnamesmall, self:get_load_proxy())
  local movein_txt = CsNpcInvitationModuleUtil.HasNpcHouseAreaSelected(npc_id) and UIUtil.get_text_by_id("NpcHouseMoveIn_MoveInTomorrow") or UIUtil.get_text_by_id("NpcHouseMoveIn_Pending_AreaSelect")
  UIUtil.set_text(self._txt_movein, movein_txt)
end

return M
