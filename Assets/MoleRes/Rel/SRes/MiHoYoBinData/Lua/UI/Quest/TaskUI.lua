task_module = task_module or {}

function task_module:get_ui_state_group_state_by_chapter(chapter_cfg)
  if is_null(chapter_cfg) then
    return 0
  end
  local ui_state = chapter_cfg.chaptertype
  return ui_state
end

function task_module:show_task_get_item_tips(show_data)
  task_module:set_task_get_item_tips_data(show_data)
  lua_event_module:send_event(lua_event_module.event_type.refresh_task_get_item_tips_data, nil)
  UIManagerInstance:open("UI/Task/TaskGetItemTips")
end

return task_module
