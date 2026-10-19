local M = G.Class("FamilyCommentReadDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentReadDialog"
  self.config.type = EUIType.Dialog
  self._translation_enabled = false
  self._translate_ready = false
end

function M:on_create()
  base.on_create(self)
  UIUtil.set_active(self._toggle_translate, not CsGameManagerUtil.gameConfig:IsCN())
  UIUtil.set_active(self._obj_translate, not CsGameManagerUtil.gameConfig:IsCN())
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._comments = data.comments or {}
  self._index = data.index or 1
  self._is_owner = data.is_owner == true
  self._on_read = data.on_read
  self._translation_enabled = false
  self._toggle_translate:SetIsOnWithoutNotify(false)
  self:_refresh()
  self._translate_ready = false
  if not CsGameManagerUtil.gameConfig:IsCN() then
    CsChatModuleUtil.InitTranslateModule(function(success, _)
      if success then
        CsChatModuleUtil.SetTranslateContextByContent("")
        self._translate_ready = true
        if self._translation_enabled then
          self:_refresh_content()
        end
      end
    end)
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_back_action))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_previous, pack(self, M._on_btn_previous_click))
  self:bind_callback(self._btn_next, pack(self, M._on_btn_next_click))
  self:bind_callback(self._toggle_translate, pack(self, M._on_toggle_translate_changed))
  self:bind_callback(self._btn_more, pack(self, M._on_btn_more_click))
end

function M:_on_back_action()
  self:close_self()
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_btn_previous_click()
  self._index = math.max(1, self._index - 1)
  self:_refresh()
end

function M:_on_btn_next_click()
  self._index = math.min(#self._comments, self._index + 1)
  self:_refresh()
end

function M:_on_toggle_translate_changed(is_on)
  self._translation_enabled = is_on
  self:_refresh_content()
end

function M:_on_btn_more_click()
  if is_null(self._data) then
    return
  end
  local menus = {}
  if self._is_owner then
    table.insert(menus, {
      desc = UIUtil.get_text_by_id("Liuyanban_Delete_Comment"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_btn_delete_click)
    })
  end
  table.insert(menus, {
    desc = UIUtil.get_text_by_id("Menu_Tip_Off"),
    valid = true,
    close = true,
    call_back_action = pack(self, M._on_btn_report_click)
  })
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1),
    state = 1,
    menus = menus
  })
end

function M:_on_btn_delete_click()
  local guid = self._data and self._data.Guid
  if is_null(guid) then
    return
  end
  family_comment_module:open_delete_confirm_dialog({
    guid_list = {guid},
    tag_list = {},
    on_confirm = function(guid_list)
      family_comment_module:delete_comments(guid_list)
      self:close_self()
      return true
    end
  })
end

function M:_on_btn_report_click()
  self:_open_report_menu()
end

function M:_refresh()
  local data = self._comments[self._index]
  if is_null(data) then
    self:close_self()
    return
  end
  self._data = data
  if self._is_owner and not data.IsRead and family_comment_module:read_comment(data.Guid) and self._on_read then
    self._on_read(data.Guid)
  end
  UIUtil.set_text(self._txt_player_name, data.PlayerNickname or "")
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(data.Timestamp or 0)
  UIUtil.set_text(self._txt_time, TextMapFormatUtil.FormatDateYMD(date_time))
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), data.AvatarId or 0)
  UIUtil.set_active(self._img_avatar, head_cfg ~= nil)
  if head_cfg then
    UIUtil.set_image(self._img_avatar, head_cfg.respath, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_tag, table.concat(family_comment_module:get_comment_tags(data), " "))
  UIUtil.set_active(self._btn_previous, self._index > 1)
  UIUtil.set_active(self._btn_next, self._index < #self._comments)
  self:_refresh_content()
end

function M:_refresh_content()
  local content = self._data and self._data.Content or ""
  if not self._translation_enabled or not string.is_valid(content) then
    UIUtil.set_text(self._txt_comment, content)
    return
  end
  local guid = self._data and self._data.Guid
  local target_language = CsLocalizationManagerUtil.curLanguageStr or "zh-cn"
  local translated = family_comment_module:get_cached_translation(guid, target_language)
  if string.is_valid(translated) then
    UIUtil.set_text(self._txt_comment, translated)
    return
  end
  UIUtil.set_text(self._txt_comment, content)
  if not self._translate_ready then
    return
  end
  family_comment_module:request_comment_translation(guid, content, target_language, function(success, result)
    if not success or is_null(self._txt_comment) then
      return
    end
    local current_guid = self._data and self._data.Guid
    local current_language = CsLocalizationManagerUtil.curLanguageStr or "zh-cn"
    if self._translation_enabled and current_guid == guid and current_language == target_language then
      UIUtil.set_text(self._txt_comment, result)
    end
  end)
end

function M:_open_report_menu()
  if is_null(self._data) then
    return
  end
  report_module:open_report_page({
    target = report_module.report_target.message_board,
    player_name = self._data.PlayerNickname,
    target_uid = self._data.PlayerUid,
    target_message = self._data.Content,
    station_message_guid = self._data.Guid
  })
end

return M
