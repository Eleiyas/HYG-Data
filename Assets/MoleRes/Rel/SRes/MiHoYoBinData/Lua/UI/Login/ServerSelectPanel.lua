local M = G.Class("ServerSelectPanel", G.UIPanel)
local base = G.UIPanel
local uid_input_class = "UI/GMPage/GMUIDInput"

function M:init()
  base.init(self)
  self._uid_input_panel = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_enter_game, pack(self, M.on_login))
  self:bind_callback(self._btn_background, pack(self, M.on_login))
  self.game_config = CsGameManagerUtil.gameConfig
  if ApplicationUtil.IsEnableGM() and self.game_config.isApprovalBranch == false then
    self:add_panel_async(uid_input_class, nil, function(panel)
      if self.holder == nil or self.holder._state == EUIState.Destroy or is_null(self.trans) then
        panel:Delete()
      else
        self:_reset_panel_layout(panel)
        self._uid_input_panel = panel
        panel:set_active(true)
      end
    end)
  end
  local version_info = ""
  local game_config = CsGameManagerUtil.gameConfig
  version_info = game_config.version .. "_" .. "C" .. game_config.changeList .. "_" .. "R" .. game_config:GetResourceReversion() .. "_" .. "D" .. game_config:GetDataReversion()
  UIUtil.set_text(self._txt_info, version_info)
end

function M:_reset_panel_layout(panel)
  panel.trans:SetParent(self.trans)
  panel.trans:SetLocalPosition(0, 0, 0)
  panel.trans:SetLocalScale(1, 1, 1)
  panel.rect_trans:SetOffsetMax(0, 0)
  panel.rect_trans:SetOffsetMin(0, 0)
end

function M:on_login()
  if self.server_list == nil or #self.server_list == 0 then
    return
  end
  local current = self.server_list[self._dp_servers.value + 1]
  CsNetManagerUtil.SelectServer(current)
  if self.action then
    if self._uid_input_panel then
      local uid = self._uid_input_panel:get_uid()
      self.action(uid)
    else
      self.action(0)
    end
  end
end

function M:refresh()
  if not is_null(self._extra_data) then
    self.action = self._extra_data.onChoicePress
  end
  self:_init_server_list()
  local show_selector = #self.server_list > 1
  UIUtil.set_active(self._dp_servers, show_selector)
  UIUtil.set_active(self._btn_enter_game, true)
  InputManagerIns:unlock_input(input_lock_from.Common)
end

function M:_init_server_list()
  self._dp_servers:ClearOptions()
  self.server_list = list_to_table(CsNetManagerUtil.GetAllAddress())
  for i = 1, #self.server_list do
    self:_add_drop_item(self._dp_servers, tostring(self.server_list[i].title))
  end
  self._dp_servers:RefreshShownValue()
  self:bind_callback(self._dp_servers, pack(self, M._on_select))
  self._dp_servers.onShowHide:AddListener(pack(self, M._on_dropdown_show_hide))
  self:_update_arrow(false)
  self:_on_select()
end

function M:_on_dropdown_show_hide(is_active)
  self:_update_arrow(is_active)
end

function M:_on_select(index)
  local current = self.server_list[self._dp_servers.value + 1]
  if current and current.name then
    CsMiHoYoSDKManagerUtil.SetServerId(current.name)
  end
end

function M:_add_drop_item(drop_down, item)
  local drop_item = Dropdown.OptionData()
  drop_item.text = item
  drop_down.options:Add(drop_item)
end

function M:_update_arrow(is_active)
  UIUtil.set_active(self._trans_arrow_up, is_active)
  UIUtil.set_active(self._trans_arrow_down, not is_active)
end

function M:on_destroy()
  base.on_destroy(self)
  self._dp_servers.onShowHide:RemoveAllListeners()
end

return M
