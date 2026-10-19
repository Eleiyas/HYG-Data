local M = G.Class("FamilyCommentMainPage", G.UIWindow)
local base = G.UIWindow
local item_cls = "UI/FamilyComment/FamilyCommentCommentItem"
local label_item_cls = "UI/FamilyComment/FamilyCommentLabelItem"
local delete_panel_cls = "UI/FamilyComment/FamilyCommentDeletePanel"
local comment_short_height = 395
local comment_long_height = 540
local comment_long_text_threshold = 40

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentMainPage"
  self.config.type = EUIType.Page
  self._comments = {}
  self._comment_items = {}
  self._selected = {}
  self._selected_tags = {}
  self._tag_items = {}
  self._edit_mode = false
  self._waterfall_inited = false
  self._default_title_icon = nil
end

function M:on_create()
  base.on_create(self)
  self._default_title_icon = self._icon_title.sprite
  self:_init_tag_items()
  self:_init_bottom_delete()
end

function M:on_enable()
  base.on_enable(self)
  self._is_owner = player_module:is_local_player_scene_owner()
  self._btn_like.interactable = not self._is_owner
  self._selected = {}
  self._selected_tags = {}
  self._edit_mode = false
  self._delete_panel:set_active(false, true)
  self:_refresh_all()
end

function M:on_close()
  base.on_close(self)
  if self._is_owner then
    family_comment_module:read_all_comments(self._comments)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.family_comment_data_changed, function()
    self:_refresh_all()
  end)
  self:add_lua_listener(lua_event_module.event_type.family_comment_like_changed, function()
    self:_refresh_like()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_back_action))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_leave_comment, pack(self, M._on_btn_leave_comment_click))
  self:bind_callback(self._btn_edit_comments, pack(self, M._on_btn_edit_comments_click))
  self:bind_callback(self._btn_like, pack(self, M._on_btn_like_click))
  self:bind_callback(self._btn_social_level, pack(self, M._on_btn_social_level_click))
  self:bind_callback(self._btn_setting, pack(self, M._on_btn_setting_click))
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
end

function M:_on_back_action()
  if self._edit_mode then
    self:_set_edit_mode(false)
  else
    self:close_self()
  end
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_btn_leave_comment_click()
  local max_count_cfg = ExcelDataUtil.get_value(typeof(BMessageBoardCfg), 2)
  local max_count = max_count_cfg and tonumber(max_count_cfg.value)
  if max_count and 0 <= max_count and max_count <= CsPlayerVisitModuleUtil.GetPlayerLeaveMessageCount(player_module:get_player_uid()) then
    UIUtil.show_tips_by_text_id("Market_Message_SendFail_Tip")
    return
  end
  family_comment_module:open_edit_dialog()
end

function M:_on_btn_edit_comments_click()
  self:_set_edit_mode(true)
end

function M:_on_btn_like_click()
  local is_liked = family_comment_module:is_liked()
  family_comment_module:set_liked(not is_liked)
  self._animator_like:ResetTrigger("selected")
  self._animator_like:ResetTrigger("normal")
  self._animator_like:SetTrigger(is_liked and "normal" or "selected")
end

function M:_on_btn_social_level_click()
  family_comment_module:open_level_dialog()
end

function M:_on_btn_setting_click()
end

function M:_on_btn_info_click()
  common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.family_comment)
end

function M:_refresh_all()
  self._comments = family_comment_module:get_comments()
  self:_refresh_states()
  self:_refresh_like()
  self:_refresh_tags()
  self:_refresh_social_level()
  self:_refresh_comments()
end

function M:_refresh_states()
  self._ui_top_state:SetState(self._is_owner and 0 or 1)
  self._ui_bottom_state:SetState(self._is_owner and 0 or 1)
  self._ui_comment_state:SetState(0 < #self._comments and 1 or 0)
  self._btn_edit_comments.interactable = self._is_owner
  UIUtil.set_text(self._txt_comment_count, TextMapFormatUtil.FormatInteger(#self._comments))
  UIUtil.set_text_by_id(self._txt_permission_status, "Liuyanban_Public")
end

function M:_refresh_like()
  local is_liked = family_comment_module:is_liked()
  self._btn_like:SetSelectTransition(is_liked and 0 or 1)
  UIUtil.set_text(self._txt_like_count, TextMapFormatUtil.FormatAbbreviation(family_comment_module:get_like_count()))
end

function M:_refresh_tags()
  local tags = family_comment_module:get_hot_tags()
  for index, item in ipairs(self._tag_items) do
    local tag = tags[index]
    item:set_data(index, tag, tag and self._selected_tags[tag.id] == true, self._edit_mode)
  end
  local title_icon = tags[1] and tags[1].icon
  if string.is_valid(title_icon) then
    UIUtil.set_image(self._icon_title, title_icon, self:get_load_proxy())
  else
    self._icon_title.sprite = self._default_title_icon
  end
  UIUtil.set_active(self._trans_tag_empty, #self._comments > 0 and #tags == 0)
end

function M:_init_tag_items()
  local label_transforms = {
    self._trans_lable1,
    self._trans_lable2,
    self._trans_lable3,
    self._trans_lable4,
    self._trans_lable5,
    self._trans_lable6,
    self._trans_lable7
  }
  for index, parent in ipairs(label_transforms) do
    local trans = self._label_item
    if 1 < index then
      local obj = UIUtil.load_prefab_set_parent(self._label_item.gameObject, parent)
      trans = obj.transform
    end
    local item = self:add_panel(label_item_cls, trans)
    self._tag_items[index] = item
    if index == 1 then
      item:set_icon_type(0)
    elseif index <= 4 then
      item:set_icon_type(1)
    else
      item:set_icon_type(2)
    end
  end
end

function M:_init_bottom_delete()
  self._delete_panel = self:add_panel(delete_panel_cls, self._trans_delete)
  self._delete_panel:set_active(false, true)
end

function M:on_label_item_selection_changed(tag, is_on)
  if tag then
    self._selected_tags[tag.id] = is_on or nil
  end
  self:_refresh_delete_text()
end

function M:_refresh_delete_text()
  local count = 0
  for _, selected in pairs(self._selected) do
    if selected then
      count = count + 1
    end
  end
  for _, selected in pairs(self._selected_tags) do
    if selected then
      count = count + 1
    end
  end
  self._delete_panel:set_selected_count(count)
end

function M:on_delete_panel_cancel()
  self:_set_edit_mode(false)
end

function M:on_delete_panel_delete()
  local guid_list = {}
  for guid, selected in pairs(self._selected) do
    if selected then
      table.insert(guid_list, guid)
    end
  end
  local tag_list = {}
  for _, item in ipairs(self._tag_items) do
    local tag = item:get_tag()
    if tag and self._selected_tags[tag.id] then
      table.insert(tag_list, tag)
    end
  end
  if #guid_list == 0 and #tag_list == 0 then
    return
  end
  family_comment_module:open_delete_confirm_dialog({
    guid_list = guid_list,
    tag_list = tag_list,
    on_confirm = pack(self, M._on_delete_confirm)
  })
end

function M:_on_delete_confirm(guid_list, tag_list)
  family_comment_module:delete_comments(guid_list)
  family_comment_module:delete_tags(tag_list)
  self:_set_edit_mode(false)
  return true
end

function M:_refresh_social_level()
  local data = family_comment_module:get_social_level()
  UIUtil.set_text(self._txt_social_level, UIUtil.get_text_by_id("Liuyanban_Lv") .. TextMapFormatUtil.FormatInteger(data.level))
  self._slider_social_level.value = data.progress
  UIUtil.set_image(self._icon_level, data.icon, self:get_load_proxy())
end

function M:_refresh_comments()
  local on_change = pack(self, M._refresh_comment_item)
  
  local function get_height(index)
    return self:_get_comment_item_height(index)
  end
  
  if self._waterfall_inited then
    self._waterfall_comments:ReLoad(on_change, get_height, #self._comments)
  else
    self._waterfall_comments:Init(on_change, get_height, #self._comments)
    self._waterfall_inited = true
  end
end

function M:_get_comment_item_height(index)
  local data = self._comments[index + 1]
  local content = data and data.Content or ""
  if CsUIUtil.GetStringCount(content) > comment_long_text_threshold then
    return comment_long_height
  end
  return comment_short_height
end

function M:_refresh_comment_item(trans, index)
  local instance_id = trans:GetInstanceID()
  local item = self._comment_items[instance_id]
  if is_null(item) then
    item = self:add_panel(item_cls, trans)
    self._comment_items[instance_id] = item
  end
  local data_index = index + 1
  local data = self._comments[data_index]
  local guid = data and data.Guid
  item:set_data(data_index, data, self._is_owner, self._edit_mode, family_comment_module:get_comment_tags(data), guid and self._selected[guid] == true)
end

function M:_set_edit_mode(enabled)
  self._edit_mode = enabled
  self._selected = {}
  self._selected_tags = {}
  self._delete_panel:set_active(enabled)
  self:_refresh_tags()
  self:_refresh_delete_text()
  for _, item in pairs(self._comment_items) do
    item:set_edit_mode(enabled, false)
  end
end

function M:is_edit_mode()
  return self._edit_mode
end

function M:on_comment_item_click(index)
  if self._edit_mode then
    return
  end
  family_comment_module:open_read_dialog({
    comments = self._comments,
    index = index,
    is_owner = self._is_owner,
    on_read = pack(self, M._on_comment_read)
  })
end

function M:_on_comment_read(guid)
  for _, item in pairs(self._comment_items) do
    item:set_read(guid)
  end
end

function M:on_comment_item_select(guid, is_on)
  if is_null(guid) then
    return
  end
  self._selected[guid] = is_on or nil
  self:_refresh_delete_text()
end

return M
