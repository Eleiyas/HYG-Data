appearance_module = appearance_module or {}

function appearance_module:add_event()
  appearance_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function appearance_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function appearance_module:save_all()
  return CsAppearanceManagerUtil.SaveAll()
end

function appearance_module:set_image_color_by_id(img, unlockId)
  CsAppearanceManagerUtil.SetImageColorById(img, unlockId)
end

function appearance_module:update_player_euler_angles_y(euler_angle_y)
  CsAppearanceManagerUtil.UpdatePlayerEulerAnglesY(euler_angle_y)
end

function appearance_module:get_player_all_cloth_make_guid_and_num()
  return CsAppearanceModuleUtil.GetPlayerAllClothMakeGuidAndNum()
end

function appearance_module:check_tab_type_red_point_state(tab_type)
  local ids = appearance_module:get_change_outfit_ids_by_tab_id(tab_type) or {}
  for _, id in ipairs(ids) do
    if red_point_module:is_recorded_with_id(red_point_module.red_point_type.appearance_left_type, id) then
      return true
    end
  end
  return false
end

function appearance_module:change_pose_by_tag(tag)
  CsAppearanceManagerUtil.ChangePoseByTag(tag)
end

function appearance_module:is_holding_dress_up_holdable()
  return CsAppearanceManagerUtil.IsHoldingDressupHoldable()
end

function appearance_module:get_clothing_guids(tags, sort_type)
  return list_to_table(CsAppearanceManagerUtil.GetClothingGuids(tags, sort_type)) or {}
end

function appearance_module:clothing_is_worn_by_guid(guid)
  return CsAppearanceManagerUtil.ClothingIsWornByGuid(guid)
end

function appearance_module:create_temp_player(player_root)
  CsAppearanceManagerUtil.CreateTempPlayer(player_root)
end

function appearance_module:destroy_temp_player()
  CsAppearanceManagerUtil.DestroyTempPlayer()
end

function appearance_module:put_on_cloth_by_guid(guid)
  return CsAppearanceManagerUtil.PutOnClothByGuid(guid)
end

function appearance_module:take_off_cloth_by_guid(guid)
  return CsAppearanceManagerUtil.TakeOffClothByGuid(guid)
end

function appearance_module:reset_cloth()
  return CsAppearanceManagerUtil.ResetCloth()
end

function appearance_module:take_off_all_cloth()
  return CsAppearanceManagerUtil.TakeOffAllCloth()
end

function appearance_module:cloth_can_undo()
  return CsAppearanceManagerUtil.ClothCanUndo()
end

function appearance_module:cloth_can_redo()
  return CsAppearanceManagerUtil.ClothCanRedo()
end

function appearance_module:cloth_undo_last_action()
  return CsAppearanceManagerUtil.ClothUndoLastAction()
end

function appearance_module:cloth_redo_next_action()
  return CsAppearanceManagerUtil.ClothRedoNextAction()
end

function appearance_module:cloth_is_need_save()
  return CsAppearanceManagerUtil.ClothIsNeedSave()
end

function appearance_module:set_cloth_show_state_by_part_ids(part_ids, is_show)
  return CsAppearanceManagerUtil.SetClothShowStateByPartIds(part_ids or {}, is_show)
end

function appearance_module:get_attrib_ids(outfit_id, sort_type, is_color)
  return list_to_table(CsAppearanceManagerUtil.GetAttribIds(outfit_id, sort_type, is_color or false)) or {}
end

function appearance_module:attrib_is_active(cfg_id)
  return CsAppearanceManagerUtil.AttribIsActive(cfg_id)
end

function appearance_module:get_attrib_ids_by_type(attrib_type)
  return list_to_table(CsAppearanceModuleUtil.GetAttribIdsByType(attrib_type))
end

function appearance_module:active_attrib_by_id(cfg_id)
  return CsAppearanceManagerUtil.ActiveAttribById(cfg_id)
end

function appearance_module:reset_attrib()
  return CsAppearanceManagerUtil.ResetAttrib()
end

function appearance_module:inactive_all_attrib()
  return CsAppearanceManagerUtil.InactiveAllAttrib()
end

function appearance_module:attrib_can_undo()
  return CsAppearanceManagerUtil.AttribCanUndo()
end

function appearance_module:attrib_can_redo()
  return CsAppearanceManagerUtil.AttribCanRedo()
end

function appearance_module:attrib_undo_last_action()
  return CsAppearanceManagerUtil.AttribUndoLastAction()
end

function appearance_module:attrib_redo_next_action()
  return CsAppearanceManagerUtil.AttribRedoNextAction()
end

function appearance_module:attrib_is_need_save()
  return CsAppearanceManagerUtil.AttribIsNeedSave()
end

return appearance_module
