tutorial_module = tutorial_module or {}

function tutorial_module:add_event()
  tutorial_module:remove_event()
  self._events = {}
  self._events[EventID.Tutorial.ShowTutorialEmpty] = pack(self, self._show_tutorial_empty)
  self._events[EventID.Tutorial.LuaShowTutorial] = pack(self, self._show_tutorial)
  self._events[EventID.Tutorial.LuaCloseTutorial] = pack(self, self._close_tutorial)
  self._events[EventID.Tutorial.LuaCloseTutorialPage] = pack(self, self._close_tutorial_page)
  self._events[EventID.Tutorial.OnTutorialStart] = pack(self, self._update_graph_ui_dynamic_key)
  self._events[EventID.Tutorial.LuaOpenTutorialCameraMode] = pack(self, self.open_tutorial_camera_mode_page)
  self._events[EventID.Tutorial.LuaShowTutorialSkip] = pack(self, self.show_skip_btn)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function tutorial_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function tutorial_module:_show_tutorial_empty()
  UIManagerInstance:open("UI/Tutorial/TutorialEmptyPage")
end

function tutorial_module:_show_tutorial(data)
  if is_null(data) then
    return
  end
  local page = UIManagerInstance:is_show("UI/Tutorial/TutorialPage")
  if page then
    page:show_tutorial(data)
  else
    UIManagerInstance:open("UI/Tutorial/TutorialPage", data)
  end
end

function tutorial_module:_close_tutorial(data)
  if is_null(data) then
    return
  end
  local page = UIManagerInstance:is_show("UI/Tutorial/TutorialPage")
  if page then
    page:close_tutorial(data)
  end
end

function tutorial_module:_close_tutorial_page()
  local page = UIManagerInstance:is_show("UI/Tutorial/TutorialPage")
  if page then
    page:close_page()
  end
end

function tutorial_module:open_tutorial_handbook_page()
  tutorial_module:reset_hardware_info(InputManagerIns.is_touch() and 2 or 1)
  if tutorial_module.tutorial_items_data and #tutorial_module.tutorial_items_data > 0 then
    UINavigatorIns.visible_phone_page(false)
    UIManagerInstance:open("UI/TutorialNew/TutorialHandBookNewPage")
  else
    UIUtil.show_tips_by_text_id("HandBookNoUnlock")
  end
end

function tutorial_module:open_tutorial_handbook_page_with_module_id(module_id)
  tutorial_module:reset_hardware_info(InputManagerIns.is_touch() and 2 or 1)
  if tutorial_module.tutorial_items_data and #tutorial_module.tutorial_items_data > 0 then
    UINavigatorIns.visible_phone_page(false)
    UIManagerInstance:open("UI/TutorialNew/TutorialHandBookNewPage", {module_id = module_id})
  else
    UIUtil.show_tips_by_text_id("HandBookNoUnlock")
  end
end

function tutorial_module:open_tutorial_handbook_single_dialog(module_id, group_id, callback)
  local data = {
    [module_id] = {
      [group_id] = {}
    }
  }
  self.close_dialog_callback = callback
  UIManagerInstance:open("UI/Tutorial/TutorialHandBookPage/TutorialHandBookDialog", data)
end

function tutorial_module:open_tutorial_handbook_single_dialog_with_group_id_list(module_id, group_id_list, callback)
  local data = {
    [module_id] = {}
  }
  for _, group_id in ipairs(group_id_list) do
    data[module_id][group_id] = {}
  end
  self.close_dialog_callback = callback
  UIManagerInstance:open("UI/Tutorial/TutorialHandBookPage/TutorialHandBookDialog", data)
end

function tutorial_module:open_tutorial_camera_mode_page()
  UIManagerInstance:open("UI/Tutorial/TutorialRotationModePage")
end

function tutorial_module:show_skip_btn()
  local page = UIManagerInstance:is_show("UI/Tutorial/TutorialPage")
  if page then
    page:show_skip_btn()
  end
end

function tutorial_module:set_force(focus_data, focus_root, ui_element, scale)
  if ui_element and focus_root and focus_data then
    focus_root.pivot = ui_element.pivot
    if focus_data.framePosOffset then
      focus_root:SetPosition(ui_element.position.x + focus_data.framePosOffset.x, ui_element.position.y + focus_data.framePosOffset.y, ui_element.position.z)
    else
      focus_root.position = ui_element.position
    end
    local _, x, y, z = UIUtil.get_ui_global_scale(ui_element)
    if focus_data.frameSizeOffset then
      scale:Set(ui_element.rect.width * x + focus_data.frameSizeOffset.x, ui_element.rect.height * y + focus_data.frameSizeOffset.y)
    else
      scale:Set(ui_element.rect.width * x, ui_element.rect.height * y)
    end
    focus_root.sizeDelta = scale
  end
end

return tutorial_module
