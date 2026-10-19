local unlock_anim_name = "anim_mainpage_btn_show"
local M = G.Class("EntrancePanelButtonItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  self._anim = self.trans:GetComponent(typeof(Animation))
  self._anim_playing = false
end

function M:on_enable()
  base.on_enable(self)
  self:active_tutorial_key()
  self:refresh_text()
end

function M:on_disable()
  base.on_disable(self)
  self._anim_playing = false
end

function M:refresh(cfg)
  if cfg == nil then
    return
  end
  self._cfg = cfg
  UIUtil.set_text(self._txt_name, self:_get_display_name())
  if string.is_valid(cfg.buttonIcon) then
    UIUtil.set_image(self._img_icon, cfg.buttonIcon, self:get_load_proxy())
  end
  self:_refresh_shortcut(cfg)
  self:active_tutorial_key()
end

function M:_refresh_shortcut(cfg)
  if is_null(self._shortcut) then
    return
  end
  self._shortcut.showInKeyMouse = true
  self._shortcut.keyMouseTip = cfg.keyMouseTip
  self._shortcut.showInJoypad = true
  self._shortcut.joyPadKeyTip = cfg.joyPadKeyTip
  self._shortcut:RefreshShortCut()
end

function M:set_icon(icon_path)
  if not string.is_valid(icon_path) then
    return
  end
  UIUtil.set_image(self._img_icon, icon_path, self:get_load_proxy())
end

function M:set_name(name)
  if not string.is_valid(name) then
    return
  end
  self._name_override = name
  self:refresh_text()
end

function M:_get_display_name()
  if string.is_valid(self._name_override) then
    return self._name_override
  end
  return self._cfg and self._cfg.buttonName or ""
end

function M:active_tutorial_key()
  if is_null(self._cfg) then
    return
  end
  local tutorial_key = self._cfg.tutorialKey
  if not_null(self._tutorial_marker) and tutorial_key ~= nil and tutorial_key ~= 0 then
    self._tutorial_marker:ActiveDynamicTutorialKey(tutorial_key)
  end
end

function M:refresh_text()
  if self._cfg then
    UIUtil.set_text(self._txt_name, self:_get_display_name())
  end
end

function M:get_btn()
  return self._btn
end

function M:get_redpoint()
  return self._redpoint
end

function M:get_input_action()
  if self._cfg and string.is_valid(self._cfg.inputAction) then
    return ActionType.Act[self._cfg.inputAction]
  end
  return nil
end

function M:refresh_slider(value)
  UIUtil.set_active(self._trans_slider, true)
  self._img_slider.fillAmount = value
end

function M:hide_slider()
  UIUtil.set_active(self._trans_slider, false)
end

function M:refresh_social_bag_load(is_show)
  UIUtil.set_active(self._trans_eco, is_show)
  UIUtil.set_active(self._img_icon_planet_echo_dyanmic, is_show)
  if is_show then
    UIUtil.set_image(self._img_icon_planet_echo_dyanmic, social_module:get_current_gather_load_icon_path(), self:get_load_proxy())
  end
end

function M:get_cfg()
  return self._cfg
end

function M:_need_play_unlock_anim()
  if not self._cfg then
    return false
  end
  local extra = self:get_extra_data()
  if extra and extra.force_play_unlock_anim then
    return true
  end
  if self._cfg.animType ~= HUDButtonAnimType.Unlock then
    return false
  end
  local unlock_anim_rp_type = red_point_module.red_point_type.entrance_hud_btn_unlock_anim
  local is_played = red_point_module:is_recorded_with_id(unlock_anim_rp_type, self._cfg.buttonId)
  return not is_played
end

function M:_clear_anim_state()
  self:set_extra_data(nil)
  if not self._cfg then
    return
  end
  local unlock_anim_rp_type = red_point_module.red_point_type.entrance_hud_btn_unlock_anim
  if not red_point_module:is_recorded_with_id(unlock_anim_rp_type, self._cfg.buttonId) then
    red_point_module:record_with_id(unlock_anim_rp_type, self._cfg.buttonId)
  end
end

function M:_set_unlock_anim_end_state()
  local anim_state = self._anim:GetAnimationState(unlock_anim_name)
  if is_null(anim_state) then
    return
  end
  anim_state.normalizedTime = 1
  self._anim:Play(unlock_anim_name)
end

function M:check_unlock_anim()
  if is_null(self._anim) then
    return
  end
  if self._anim_playing then
    return
  end
  if not self:_need_play_unlock_anim() then
    self:_set_unlock_anim_end_state()
    return
  end
  self._anim:Play(unlock_anim_name)
  self:_clear_anim_state()
  self._anim_playing = true
end

return M
