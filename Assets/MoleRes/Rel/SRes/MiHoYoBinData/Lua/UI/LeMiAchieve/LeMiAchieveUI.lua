le_mi_achievement_module = le_mi_achievement_module or {}

function le_mi_achievement_module:open_le_mi_achieve_page(data)
  UIManagerInstance:open("UI/LeMiAchieve/LeMiFootprintPage", data)
end

function le_mi_achievement_module:open_le_mi_receive_dialog()
  UIManagerInstance:open("UI/LeMiAchieve/LeMiReceiveDialog")
end

function le_mi_achievement_module:open_le_mi_award_get_page(data)
  UIManagerInstance:open("UI/LeMiAchieve/LeMiAwardGetPage", data)
end

function le_mi_achievement_module:open_le_mi_detail_page(data)
  DOTween.To(function(value)
    CsHYGGlobalPostProcessManagerUtil.EnableBlur(6 - 6 * value, 1.2 + 8.8 * value)
  end, 0, 1, 0.5)
  UIManagerInstance:open("UI/LeMiAchieve/LeMiAchieveDetailPage", data)
end

function le_mi_achievement_module:init_all_achieve_plan_cls(trans_star, trans_moon, trans_sun)
  local tbl_plan = {
    star_plans = le_mi_achievement_module:init_achieve_plan_cls(trans_star),
    moon_plans = le_mi_achievement_module:init_achieve_plan_cls(trans_moon),
    sun_plans = le_mi_achievement_module:init_achieve_plan_cls(trans_sun)
  }
  return tbl_plan
end

function le_mi_achievement_module:set_all_achieve_plan_cls(all_achieve_plan, achieve_num, server_data)
  local tbl_plan = {}
  if achieve_num == le_mi_achievement_module.plan_type.star then
    tbl_plan = all_achieve_plan.star_plans
  elseif achieve_num == le_mi_achievement_module.plan_type.moon then
    tbl_plan = all_achieve_plan.moon_plans
  elseif achieve_num == le_mi_achievement_module.plan_type.sun then
    tbl_plan = all_achieve_plan.sun_plans
  end
  le_mi_achievement_module:set_achieve_plan_cls(tbl_plan, server_data)
end

function le_mi_achievement_module:init_achieve_plan_cls(trans)
  local ret_tbl = {}
  local count = trans.childCount - 1
  for i = count, 0, -1 do
    local plan_trans = trans:GetChild(i)
    local cls = {
      trans = plan_trans,
      img_icon = UIUtil.find_image(plan_trans, "Icon_Finish"),
      dt_anim = UIUtil.find_cmpt(plan_trans, nil, typeof(DOTweenAnimation))
    }
    table.insert(ret_tbl, cls)
  end
  return ret_tbl
end

function le_mi_achievement_module:set_achieve_plan_cls(tbl_plan, server_data)
  for i, cls in ipairs(tbl_plan) do
    if i < server_data.GroupStepId then
      cls.img_icon.fillAmount = 1
    elseif i == server_data.GroupStepId then
      if cls.dt_anim ~= nil and server_data.CurrentProgress > 0 and server_data.CurrentProgress ~= server_data.TargetProgress then
        cls.dt_anim:DORestart()
        cls.dt_anim:DOPlay()
      end
      cls.img_icon.fillAmount = server_data.CurrentProgress / server_data.TargetProgress
    else
      cls.img_icon.fillAmount = 0
    end
  end
end

function le_mi_achievement_module:add_achieve_tip(id)
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateMilestone) then
    return
  end
  if UIManagerInstance:is_show("UI/LeMiAchieve/LeMiFootprintPage") then
    return
  end
  if self.last_tip_id == id then
    return
  end
  self.last_tip_id = id
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.lemi_achieve_tip, {id = id})
end

return le_mi_achievement_module
