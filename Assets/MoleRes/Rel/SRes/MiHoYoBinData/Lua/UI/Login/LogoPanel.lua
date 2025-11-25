local M = G.Class("LogoPanel", G.UIPanel)
local base = G.UIPanel
local splash_duration = 3

function M:show_logo(callback)
  self._callback = callback
  if ApplicationUtil.IsUnityEditor() then
    self:_start_game()
    return
  end
  self:_set_panel_active(true, false, false)
  if CsGameManagerUtil.gameConfig:IsCN() then
    UIUtil.set_image(self._logo, "Localization/Image/zh-CN/Logo.png", self.holder:get_load_proxy())
  else
    UIUtil.set_image(self._logo, "Localization/Image/en/Logo.png", self.holder:get_load_proxy())
    UIUtil.set_active(self._txt_copyright, false)
  end
  self:play_anim("logo_enter")
  CsCoroutineManagerUtil.InvokeAfterSplashScreen(splash_duration, function()
    self:play_anim("logo_exit", function()
      self:_show_warning()
    end)
  end)
end

function M:_show_warning()
  self:_set_panel_active(false, true, false)
  UIUtil.set_text_by_id(self._txt_warning_title, "Logo_Warning_Title")
  UIUtil.set_text_by_id(self._txt_warning_content, "Logo_Warning_Content")
  self:play_anim("warning_enter")
  CsCoroutineManagerUtil.Invoke(splash_duration, function()
    self:play_anim("warning_exit", function()
      self:_show_video()
    end)
  end)
end

function M:_show_video()
  self:_set_panel_active(false, false, true)
  self:play_anim("video_enter")
  local cur_task = VideoTask()
  cur_task:InitByCfgId(self:_get_video_cfg_id())
  cur_task.screenImage = self._player_image
  
  function cur_task.onFinishPlay()
    self:_start_game()
  end
  
  CsVideoManagerUtil.Play(cur_task)
end

function M:_get_video_cfg_id()
  local cur_lan_type = LocManagerIns:get_cur_lan_type()
  if cur_lan_type == LanguageType.LanguageEn then
    return 11017
  elseif cur_lan_type == LanguageType.LanguageJp then
    return 11018
  else
    return 11016
  end
end

function M:_set_panel_active(logo, warning, video)
  UIUtil.set_active(self._logo_panel, logo)
  UIUtil.set_active(self._warning_panel, warning)
  UIUtil.set_active(self._video_panel, video)
end

function M:_start_game()
  self._start_game_called = true
  EventCenter.Broadcast(EventID.onLogoViewClose)
  if self._callback then
    self._callback()
  end
end

function M:on_destroy()
  base.on_destroy(self)
  if not self._start_game_called then
    self:_start_game()
  end
end

return M
