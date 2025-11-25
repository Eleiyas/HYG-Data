tracking_module = tracking_module or {}

function tracking_module:set_tracking_ui_title(track_data, img_icon, txt_title, load_proxy)
  local title_str = track_data.title_str or ""
  local is_show_feature_icon = false
  if track_data.source_type == tracking_module.data_source_type.recipe then
    is_show_feature_icon = true
    recipe_module:set_recipe_icon(img_icon, track_data.source_id, load_proxy, true)
  elseif track_data.source_type == tracking_module.data_source_type.mitaicobuild then
    is_show_feature_icon = false
  elseif track_data.source_type == tracking_module.data_source_type.companion_star then
    local npc_cfg = LocalDataUtil.get_value(typeof(CS.BNpcCfg), track_data.source_id)
    if npc_cfg then
      UIUtil.set_image(img_icon, npc_cfg.iconnamesmall, load_proxy)
      is_show_feature_icon = true
    else
      is_show_feature_icon = false
    end
  elseif track_data.source_type == tracking_module.data_source_type.miyouzhu then
    is_show_feature_icon = false
  end
  UIUtil.set_text(txt_title, title_str)
  return is_show_feature_icon
end

function tracking_module:feature_jump_by_tracking_data(tracking_data)
  if is_null(tracking_data) then
    return
  end
  if tracking_data.source_type == tracking_module.data_source_type.recipe then
    recipe_module:beiwanglu_open_diy_recipe_info_page(tracking_data.source_id)
  elseif tracking_data.source_type == tracking_module.data_source_type.miyouzhu then
    npc_house_order_module:beiwanglu_open_miyouzhu_page()
  elseif tracking_data.source_type == tracking_module.data_source_type.mitaicobuild then
    UIManagerInstance:open("UI/MiTai/MiTaiCoBuildBoxPage", {
      orderId = tracking_data.source_id
    })
  elseif tracking_data.source_type == tracking_module.data_source_type.companion_star then
    companion_star_module:open_detail_by_npc_id(tracking_data.source_id)
  elseif tracking_data.source_type == tracking_module.data_source_type.lemi_achievement then
    le_mi_achievement_module:open_le_mi_achieve_page()
  elseif tracking_data.source_type == tracking_module.data_source_type.lemi_daily_task then
    le_mi_achievement_module:open_le_mi_achieve_page({show_daily = true})
  end
end

return tracking_module
