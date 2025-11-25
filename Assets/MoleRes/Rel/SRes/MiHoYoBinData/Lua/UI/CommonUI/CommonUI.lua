common_ui_module = common_ui_module or {}
common_ui_module._cname = "common_ui_module"
common_ui_module.sort_item_cls_name = "UI/CommonUI/SortItem"
common_ui_module.bg_type = {
  none = 0,
  packet = 1,
  shop = 2,
  tool_table = 3
}
common_ui_module.introduction_dialog_type = {cooking = 1}

function common_ui_module:init()
  self._events = nil
  self._cmd_handles = {}
  self._bg_background_board = nil
  self._bg_background_board_guid = 0
end

function common_ui_module:register_cmd_handler(cmd, handle)
  if self._cmd_handles[cmd] then
    Logger.LogError("This Cmd is already register: " .. cmd.name)
    return
  end
  self._cmd_handles[cmd] = handle
  NetHandlerIns:register_cmd_handler(cmd, handle)
end

function common_ui_module:unregister_cmd_handler(cmd_id)
  if not self._cmd_handles[cmd_id] then
    return
  end
  NetHandlerIns:unregister_cmd_handler(cmd_id)
  self._cmd_handles[cmd_id] = nil
end

function common_ui_module:close()
  for key, _ in pairs(self._cmd_handles) do
    NetHandlerIns:unregister_cmd_handler(key)
  end
  self._cmd_handles = {}
  self._bg_background_board = nil
  self._bg_background_board_guid = 0
end

function common_ui_module:load_bg_background_board()
  if self._bg_background_board_guid == nil then
    local guid, bg_scene = UIManagerInstance:open("UI/CommonUI/BGBackgroundBoard")
    self._bg_background_board = bg_scene
    self._bg_background_board_guid = guid
    self._bg_background_board:is_cache_ui()
  end
end

function common_ui_module:show_bg_background_board(bg_type)
  local guid, bg_scene = UIManagerInstance:open("UI/CommonUI/BGBackgroundBoard")
  self._bg_background_board = bg_scene
  self._bg_background_board_guid = guid
  self._bg_background_board:refresh(bg_type)
end

function common_ui_module:hide_bg_background_board()
  if self._bg_background_board == nil or UIManagerInstance:get_windows_by_guid(self._bg_background_board_guid) == nil then
    self._bg_background_board = nil
    self._bg_background_board_guid = nil
    return
  end
  self._bg_background_board:hide()
end

function common_ui_module:show_dialog_page(name, content, is_hide_page, yes_txt, yes_callback, no_txt, no_callback, complete_callback)
  local dialog_data = DialogData()
  local pageType = DialogPageType.Normal
  if name == "Narration" then
    pageType = DialogPageType.Narration
  elseif name == "Player" then
    pageType = DialogPageType.Player
  end
  dialog_data.name = name
  dialog_data.content = content
  dialog_data.pageType = pageType
  local option_list = {}
  if yes_txt ~= nil then
    local yes_option = {
      iconPath = "",
      content = yes_txt,
      callback = function()
        EventCenter.Broadcast(EventID.LuaCloseDialogPage, nil)
        if is_hide_page then
          EventCenter.Broadcast(EventID.LuaCloseBlank, nil)
        end
        if yes_callback then
          yes_callback()
        end
      end
    }
    table.insert(option_list, yes_option)
  end
  if no_txt ~= nil then
    local no_option = {
      iconPath = "",
      content = no_txt,
      callback = function()
        EventCenter.Broadcast(EventID.LuaCloseDialogPage, nil)
        if is_hide_page then
          EventCenter.Broadcast(EventID.LuaCloseBlank, nil)
        end
        if no_callback then
          no_callback()
        end
      end
    }
    table.insert(option_list, no_option)
  end
  dialog_data.autoNext = 0 < #option_list
  if #option_list <= 0 then
    option_list = nil
  end
  local context = {
    dialogList = {dialog_data},
    optionList = option_list,
    onComplete = complete_callback
  }
  if is_hide_page then
    EventCenter.Broadcast(EventID.LuaShowBlank, nil)
  end
  EventCenter.Broadcast(EventID.LuaOpenDialogPage, context)
end

function common_ui_module:show_introduction_dialog(introduction_dialog_type)
  UIManagerInstance:open("UI/CommonUI/IntroductionDialog", introduction_dialog_type)
end

function common_ui_module:show_item_confirm_dialog(title_txt, items, left_txt, left_callback, right_txt, right_callback, is_show_close_btn, close_callback)
  local data = {
    title_txt = title_txt,
    items = items or {},
    left_txt = left_txt,
    left_callback = left_callback,
    right_txt = right_txt,
    right_callback = right_callback,
    is_show_close_btn = is_show_close_btn or true,
    close_callback = close_callback
  }
  UIManagerInstance:open("UI/ConfirmView/ItemConfirmDialog", data)
end

function common_ui_module:show_get_grid_style_tips(id, show_time)
  UIManagerInstance:open("UI/Tips/GetGridStyleTips", {
    show_time = show_time or 1,
    id = id
  })
end

return common_ui_module
