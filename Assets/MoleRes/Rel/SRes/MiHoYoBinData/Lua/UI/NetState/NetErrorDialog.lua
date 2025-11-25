local M = G.Class("NetErrorDialog", G.UIWindow)
local base = G.UIWindow
local relogin_type = ReLoginType
local Loading_scene_cls_name = "UI/Loading/LoadingPage"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NetState/NetErrorDialog"
  self.config.type = EUIType.Tip
  self.config.handle_input = true
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._yes_button, pack(self, M._press_yes))
  self:bind_callback(self._no_button, pack(self, M._press_no))
  UIUtil.set_active(self._close_button, false)
end

function M:register_events()
  self:add_evt_listener(EventID.luaShowNetError, pack(self, M._on_handle_error_again))
  self:add_evt_listener(EventID.luaCloseNetError, pack(self, M.close_self))
  self:add_evt_listener(EventID.LuaOpenLoadingScene, function()
    UIUtil.set_active(self._circle, false)
  end)
  self:add_evt_listener(EventID.luaShowMainLoginPage, function()
    UIUtil.set_active(self._circle, false)
    UIUtil.set_active(self._background, false)
    self.maskImage.enabled = false
  end)
end

function M:_on_handle_error_again(error_pack)
  if not is_null(error_pack) then
    if self:_error_handling_check(error_pack) == false then
      return
    end
    self:set_extra_data(error_pack)
    self.has_relogin = false
    self:_refresh()
  end
end

function M:on_enable()
  base.on_enable(self)
  self.has_relogin = false
  self:_refresh()
end

function M:_refresh()
  local error_pack = self._extra_data
  if is_null(error_pack) then
    self:close_self()
    return
  end
  self:_set_reLogin_type()
  self:_reset_cb()
  if error_pack.needShowPopup then
    if error_pack.infoPack then
      self:_refresh_dialog_with_info_pack(error_pack.infoPack)
    else
      self:_refresh_dialog_with_error_pack(error_pack)
    end
  end
  self.maskImage.enabled = true
  UIUtil.set_active(self._popup, error_pack.needShowPopup)
  UIUtil.set_active(self._circle, not UIManagerInstance:is_show(Loading_scene_cls_name))
  if not error_pack.needShowPopup and self.has_relogin == false then
    self:_re_login(false)
    self.has_relogin = true
  end
end

function M:_refresh_dialog_with_error_pack(error_pack)
  local info_text = UIUtil.get_text_by_id("Net_Error_Tip")
  if ApplicationUtil.IsDebugMode() then
    info_text = info_text .. [[

[local error code: ]] .. error_pack.netError:ToString() .. "(" .. tostring(error_pack.netError.value__) .. ")"
    if string.is_valid(error_pack.reasonString) then
      info_text = info_text .. " server error code:" .. tostring(error_pack.reasonString) .. "(" .. tostring(error_pack.reason) .. ")" .. " ]"
    else
      info_text = info_text .. " ]"
    end
  end
  self:_set_text(self._info_text, info_text, "")
  if error_pack.type == relogin_type.QuitGame then
    self:_set_text(self._yes_text, UIUtil.get_text_by_id("GM_QuitGame"), "re-login")
  else
    self:_set_text(self._yes_text, UIUtil.get_text_by_id("Net_Error_ReLogin"), "re-login")
  end
  self:_set_text(self._no_text, UIUtil.get_text_by_id("GM_QuitGame"), "quit")
  UIUtil.set_active(self._no_button, error_pack.type ~= relogin_type.QuitGame)
end

function M:_refresh_dialog_with_info_pack(info_pack)
  UIUtil.set_active(self._close_button, false)
  self:_set_text(self._info_text, info_pack.msg, "")
  self:_set_text(self._yes_text, info_pack.yesTxt, "")
  self:_set_text(self._no_text, info_pack.noTxt, "")
  UIUtil.set_active(self._no_button, string.is_valid(info_pack.noTxt))
  self._yes_cb = info_pack.yesCb
  self._no_cb = info_pack.noCb
end

function M:_press_yes()
  if self.has_relogin then
    return
  end
  self.has_relogin = true
  local error_pack = self._extra_data
  UIUtil.set_active(self._popup, false)
  UIUtil.set_active(self._circle, not error_pack.isInLogoOrLoading and not UIManagerInstance:is_show(Loading_scene_cls_name))
  UIUtil.set_active(self._background, not UIManagerInstance:is_show(Loading_scene_cls_name))
  if self._yes_cb then
    self._yes_cb()
    self:_reset_cb()
  else
    self:_re_login(true)
  end
end

function M:_re_login(needReset)
  if not is_null(CsNetManagerUtil) then
    CsNetManagerUtil.ReLogin(needReset)
  end
end

function M:_set_reLogin_type()
  local error_pack = self._extra_data
  if not is_null(CsNetManagerUtil) then
    CsNetManagerUtil.reloginType = error_pack.type
  end
end

function M:_press_no()
  if self.has_relogin then
    return
  end
  self.has_relogin = true
  if self._no_cb then
    local error_pack = self._extra_data
    UIUtil.set_active(self._popup, false)
    UIUtil.set_active(self._circle, not error_pack.isInLogoOrLoading and not UIManagerInstance:is_show(Loading_scene_cls_name))
    UIUtil.set_active(self._background, not UIManagerInstance:is_show(Loading_scene_cls_name))
    self._no_cb()
    self:_reset_cb()
  else
    ApplicationUtil.QuitGame()
  end
end

function M:_set_text(text, txt, default_txt)
  if text then
    if string.is_valid(txt) then
      UIUtil.set_text(text, txt)
    elseif string.is_valid(default_txt) then
      UIUtil.set_text(text, default_txt)
    end
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  if not self.is_active then
    return
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.ButtonSouth, self._yes_button)
end

function M:_handle_confirm(action)
  self:_press_yes()
end

function M:handle_back(action)
  self:_press_no(self._no_callback)
  action.handled = true
end

function M:_reset_cb()
  self._yes_cb = nil
  self._no_cb = nil
end

function M:_error_handling_check(error_pack)
  local old_error_pack = self:get_extra_data()
  if not old_error_pack then
    return true
  end
  if not error_pack then
    return false
  end
  if self._popup.activeInHierarchy and not error_pack.needShowPopup then
    Logger.Log("新的网络错误无法覆盖就的网络错误，直接抛弃")
    return false
  end
  return true
end

return M
