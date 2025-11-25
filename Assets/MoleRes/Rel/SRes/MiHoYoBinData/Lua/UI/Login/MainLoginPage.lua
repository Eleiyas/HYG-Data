local M = G.Class("MainLoginPage", G.UIWindow)
local base = G.UIWindow
local logo_panel_cls = "UI/Login/LogoPanel"
local server_select_cls = "UI/Login/ServerSelectPanel"
local download_panel_cls = "UI/Login/DownloadPanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Login/LoginPage"
  self.config.type = EUIType.Page
  self._game_config = CsGameManagerUtil.gameConfig
  self._is_cn = self._game_config:IsCN()
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
  self._logo_panel = self:add_panel(logo_panel_cls, self._obj_logo_panel)
  self._select_panel = self:add_panel(server_select_cls, self._obj_select_panel, self:get_extra_data())
  self._download_panel = self:add_panel(download_panel_cls, self._obj_download_panel)
end

function M:on_enable()
  base.on_enable(self)
  local on_enable_cb = self:get_extra_data().onEnable
  if on_enable_cb ~= nil then
    on_enable_cb()
  end
  self:change_panel(self:get_extra_data().type)
  CsUIUtil.SetResolutionHeight(880)
  CsUIUtil.SetVSyncCount(0)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.luaShowMainLoginPage, pack(self, M._on_show))
end

function M:on_destroy()
  if not is_null(CsMiHoYoSDKManagerUtil) then
    CsMiHoYoSDKManagerUtil.ClearCallback()
  end
  base.on_destroy(self)
end

function M:_on_show(args)
  self:set_extra_data(args)
  local on_enable_cb = self:get_extra_data().onEnable
  if on_enable_cb ~= nil then
    on_enable_cb()
  end
  self:change_panel(self:get_extra_data().type)
end

function M:change_panel(login_type)
  self._logo_panel:set_active(login_type == MainLoginType.Logo)
  UIUtil.set_active(self._obj_waitting_panel, login_type ~= MainLoginType.Logo)
  self._select_panel:set_active(login_type == MainLoginType.ServerSelect)
  self._download_panel:set_active(login_type == MainLoginType.Download)
  self:refresh_btns(login_type)
  if login_type == MainLoginType.Logo then
    self._logo_panel:show_logo(function()
      self:change_panel(MainLoginType.Waitting)
    end)
  elseif login_type == MainLoginType.ServerSelect then
    self._select_panel:set_extra_data(self:get_extra_data())
    self._select_panel:refresh()
    self._download_panel:reset_complete()
  elseif login_type == MainLoginType.Download and self._download_panel:is_complete() then
    self:on_download_finish()
  end
end

function M:refresh_btns(login_type)
  local show_logout = CsMiHoYoSDKManagerUtil.isLoginSuccess and CsGameManagerUtil.useSDKLogin
  UIUtil.set_active(self._btn_logout, show_logout and login_type == MainLoginType.ServerSelect)
  UIUtil.set_active(self._btn_announcement, show_logout and login_type == MainLoginType.ServerSelect)
  UIUtil.set_active(self._btn_resourcedetection, login_type == MainLoginType.ServerSelect)
  UIUtil.set_active(self._btn_setting, login_type == MainLoginType.ServerSelect)
  UIUtil.set_active(self._btn_exit, login_type == MainLoginType.ServerSelect)
  UIUtil.set_active(self._btn_age_limited, self._is_cn)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_exit, pack(self, M._on_press_exit))
  self:bind_callback(self._btn_logout, pack(self, M._on_press_logout))
  self:bind_callback(self._btn_age_limited, pack(self, M._press_cadpa))
  self:bind_callback(self._btn_announcement, pack(self, M.on_press_anno))
  self:bind_callback(self._btn_setting, pack(self, M._on_click_setting))
  self:bind_callback(self._btn_resourcedetection, pack(self, M._on_press_res_fix))
end

function M:_on_press_exit()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("MainLoginPage_TipExit"), UIUtil.get_text_by_id("Common_Accept"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    ApplicationUtil.QuitGame()
  end)
  popup:show()
end

function M:_on_press_logout()
  if CsMiHoYoSDKManagerUtil then
    CsMiHoYoSDKManagerUtil.SDKLogout(pack(self, M._on_logout))
  end
end

function M:_press_cadpa()
  UIManagerInstance:open("UI/Login/CADPAInfoDialog")
end

function M:on_press_anno()
  CsMiHoYoSDKManagerUtil.ShowAnnouncement(true)
end

function M:_on_click_setting()
  UIManagerInstance:open("UI/Setting/SettingPage", {is_login_page = true})
end

function M:_on_press_res_fix()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Download_Clear_Version_File"), UIUtil.get_text_by_id("Common_Accept"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    CsUIUtil.ClearDownloadVersionFile()
    local popup2 = UIUtil.get_confirm_popup()
    popup2:set_texts(UIUtil.get_text_by_id("Download_Reenter_Game"), UIUtil.get_text_by_id("Common_Accept"))
    popup2:set_style(ConfirmPopupStyle.ForcedPopup)
    popup2:show()
    if self:get_extra_data().type == MainLoginType.Download then
      CsNetManagerUtil.ClearSelection()
      CsNetManagerUtil.RestartProcess()
    end
  end)
  popup:show()
end

function M:_on_logout(msg)
  Logger.Log(msg)
  local response = JSON.Parse(msg)
  local ret = response:GetValueOrDefault("ret", nil).AsInt
  if response and MHYSDKC.Code.SUCCESS == ret then
    CsMiHoYoSDKManagerUtil.isLoginSuccess = false
    CsNetManagerUtil.ClearSelection()
    CsNetManagerUtil.RestartProcess()
  end
end

function M:on_download_finish()
  local show_logout = CsMiHoYoSDKManagerUtil.isLoginSuccess and CsGameManagerUtil.useSDKLogin
  UIUtil.set_active(self._btn_announcement, show_logout)
  UIUtil.set_active(self._btn_logout, show_logout)
  UIUtil.set_active(self._btn_setting, true)
  UIUtil.set_active(self._btn_exit, true)
  UIUtil.set_active(self._btn_resourcedetection, true)
end

return M
