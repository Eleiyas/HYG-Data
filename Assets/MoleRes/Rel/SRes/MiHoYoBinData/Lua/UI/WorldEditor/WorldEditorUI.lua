world_editor_module = world_editor_module or {}
world_editor_module._cname = "world_editor_module"

function world_editor_module:enter_world_editor()
  if not level_module:cur_world_type_is_main() or CsMultiplayerUtilityUtil.IsMultiplayer then
    UIUtil.show_tips_by_text_id("WorldEditor_Online_Banned_Tip")
    return false
  end
  if not_null(TutorialManager.Current) then
    TutorialManager.Current:ForceQuitTutorial()
  end
  UIManagerInstance.ui_camera.orthographic = true
  RuntimeWorldEditor.Current:EnterEditMode()
  return true
end

function world_editor_module:exit_world_editor()
  RuntimeWorldEditor.Current:ExitEditMode()
  local window = UIManagerInstance:get_window_by_class("UI/WorldEditor/WorldEditorPage")
  if window then
    window:close_self()
  end
  lua_event_module:send_event(lua_event_module.event_type.set_click_scene_active, true)
  UIManagerInstance.ui_camera.orthographic = false
end

return world_editor_module or {}
