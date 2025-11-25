local M = G.Class("UINavigator")
M._cname = "UINavigator"

function M.enter_photograph(enter_mode)
  if UIManagerInstance:can_start_window_ability("UI/Photography/PhotographyPage") == false then
    return
  end
  UIManagerInstance:open("UI/Photography/PhotographyPage")
end

function M.enter_phone_page()
  if not CsUIUtil.CheckAvatarPostureMatchesLyingOrSitting() then
    if GameplayUtility.Player.ShouldShowPhonePageUnavailableTip() then
      UIUtil.show_tips_by_text_id("Common_Page_Lock_Tip")
      return
    end
    if GameplayUtility.Player.UIDefaultValidatePlayerStates() == false then
      return
    end
    if UIManagerInstance:can_start_window_ability("UI/Phone/PhonePage") == false then
      return
    end
  end
  if phone_module.in_exit_state == true or phone_module.in_enter_state == true then
    return
  end
  local _, phone_page = UIManagerInstance:open("UI/Phone/PhonePage")
  if not is_null(phone_page) then
    phone_page:enter_phone_page_state()
  end
  M.visible_phone_page(true)
end

function M.visible_phone_page(b_show)
  local phone_page = UIManagerInstance:is_show("UI/Phone/PhonePage")
  if is_null(phone_page) or is_null(phone_page.trans) then
    return
  end
  local canvas_group = phone_page.trans:GetComponent(typeof(CanvasGroup))
  if is_null(canvas_group) then
    canvas_group = phone_page.game_obj:AddComponent(typeof(CanvasGroup))
  end
  if is_null(canvas_group) then
    return
  end
  if b_show then
    canvas_group.alpha = 1
  else
    canvas_group.alpha = 0
  end
end

function M.set_phone_enter_anim_speed(speed)
  local phone_page = UIManagerInstance:is_show("UI/Phone/PhonePage")
  if is_null(phone_page) then
    return
  end
  if is_null(phone_page.binder) then
    return
  end
  phone_page.binder:SetEnterAnimSpeed(speed)
end

function M.open_luca_heart_page()
  luca_heart_module:enter_luca_heart()
end

return M
