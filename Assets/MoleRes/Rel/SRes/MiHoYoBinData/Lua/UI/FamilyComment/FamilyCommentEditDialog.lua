local M = G.Class("FamilyCommentEditDialog", G.UIWindow)
local base = G.UIWindow
local tag_item_cls = "UI/FamilyComment/FamilyCommentEditTagItem"
local candidate_tag_count = 6
local selected_tag_limit = 6

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentEditDialog"
  self.config.type = EUIType.Dialog
  self._selected_tags = {}
  self._candidate_tags = {}
  self._candidate_tag_items = {}
  self._selected_tag_items = {}
  self._tag_pool_by_group = {}
  self._tag_group_ids = {}
  self._tag_group_index = {}
  self._comment_content = ""
  self._pending_delete_tag_index = nil
  self._max_comment_chars = 0
end

function M:on_create()
  base.on_create(self)
  local message_board_cfg = ExcelDataUtil.get_value(typeof(BMessageBoardCfg), 1)
  local config_max_comment_chars = message_board_cfg and tonumber(message_board_cfg.value) or 0
  self._max_comment_chars = 0 < config_max_comment_chars and config_max_comment_chars or self._input_comment.maxCharacters
  self._input_comment.maxCharacters = self._max_comment_chars
  self:_init_candidate_tag_items()
  self:_ensure_selected_tag_items(1)
  self._selected_tag_items[1]:set_active(false)
  UIUtil.set_active(self._trans_letter_paper, false)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_player()
  self._selected_tags = {}
  self._candidate_tags = {}
  self._comment_content = ""
  self._pending_delete_tag_index = nil
  self._input_comment.text = ""
  self:_init_tag_pool()
  self:_roll_tags()
  self:_refresh_content()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_back_action))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_roll_tags, pack(self, M._on_btn_roll_tags_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  self._input_comment.onValueChanged:RemoveAllListeners()
  self._input_comment.onValueChanged:AddListener(pack(self, M._on_input_comment_changed))
end

function M:on_destroy()
  base.on_destroy(self)
  self._input_comment.onValueChanged:RemoveAllListeners()
end

function M:_on_back_action()
  self:close_self()
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_btn_roll_tags_click()
  self:_roll_tags()
end

function M:_on_btn_confirm_click()
  self:_submit()
end

function M:on_edit_tag_item_click(index, is_selected)
  if is_selected then
    if self._pending_delete_tag_index == index then
    end
    self._pending_delete_tag_index = index
    self:_refresh_selected_tags()
  else
    self._pending_delete_tag_index = nil
    self:_select_tag(index)
  end
end

function M:on_edit_tag_item_delete_click(index)
  if self._pending_delete_tag_index ~= index then
    return
  end
  self:_remove_selected_tag(index)
end

function M:_on_input_comment_changed()
  self:_on_comment_changed(self._input_comment.text)
end

function M:_refresh_player()
  UIUtil.set_text(self._txt_player_name, player_module:get_player_name())
  local player_data = player_module:get_player_data()
  local avatar_id = player_data and player_data.playerServerData and player_data.playerServerData.AvatarID or 0
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id)
  UIUtil.set_active(self._img_avatar, head_cfg ~= nil)
  if head_cfg then
    UIUtil.set_image(self._img_avatar, head_cfg.respath, self:get_load_proxy())
  end
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(TimeUtil.ServerUtcTimeSeconds)
  UIUtil.set_text(self._txt_time, TextMapFormatUtil.FormatDateYMD(date_time))
end

function M:_init_candidate_tag_items()
  if #self._candidate_tag_items > 0 then
    return
  end
  self._candidate_tag_items[1] = self:add_panel(tag_item_cls, self._trans_candidate_tag_template)
  local parent = self._trans_candidate_tag_template.parent
  for index = 2, candidate_tag_count do
    local obj = GameObject.Instantiate(self._trans_candidate_tag_template.gameObject, parent)
    self._candidate_tag_items[index] = self:add_panel(tag_item_cls, obj.transform)
  end
end

function M:_ensure_selected_tag_items(count)
  for index = #self._selected_tag_items + 1, count do
    local trans = self._trans_selected_tag_template
    if 1 < index then
      local parent = self._trans_selected_tag_template.parent
      local obj = GameObject.Instantiate(self._trans_selected_tag_template.gameObject, parent)
      trans = obj.transform
    end
    self._selected_tag_items[index] = self:add_panel(tag_item_cls, trans)
  end
end

function M:_init_tag_pool()
  self._tag_pool_by_group = {}
  self._tag_group_ids = {}
  self._tag_group_index = {}
  for _, tag in ipairs(family_comment_module:get_all_social_tags()) do
    if self._tag_pool_by_group[tag.group_id] == nil then
      self._tag_pool_by_group[tag.group_id] = {}
      table.insert(self._tag_group_ids, tag.group_id)
    end
    table.insert(self._tag_pool_by_group[tag.group_id], tag)
  end
  table.sort(self._tag_group_ids)
  for index, group_id in ipairs(self._tag_group_ids) do
    self._tag_group_index[group_id] = index
  end
end

function M:_remove_tag_from_pool(tag)
  local pool = self._tag_pool_by_group[tag.group_id] or {}
  for index, pool_tag in ipairs(pool) do
    if pool_tag.id == tag.id then
      table.remove(pool, index)
      return
    end
  end
end

function M:_add_tag_to_pool(tag)
  local pool = self._tag_pool_by_group[tag.group_id]
  if pool == nil then
    return
  end
  for _, pool_tag in ipairs(pool) do
    if pool_tag.id == tag.id then
      return
    end
  end
  table.insert(pool, tag)
end

function M:_random_tag(group_id, current_tag)
  if group_id == nil then
    return nil
  end
  local pool = self._tag_pool_by_group[group_id] or {}
  if #pool <= 1 then
    return pool[1]
  end
  local index = math.random(1, #pool)
  if current_tag and pool[index].id == current_tag.id then
    index = index % #pool + 1
  end
  return pool[index]
end

function M:_roll_tags(group_id)
  if group_id then
    local index = self._tag_group_index[group_id]
    if index and index <= candidate_tag_count then
      self._candidate_tags[index] = self:_random_tag(group_id, self._candidate_tags[index])
    end
  else
    local count = math.min(candidate_tag_count, #self._tag_group_ids)
    for index = 1, count do
      local current_group_id = self._tag_group_ids[index]
      self._candidate_tags[index] = self:_random_tag(current_group_id, self._candidate_tags[index])
    end
    for index = count + 1, candidate_tag_count do
      self._candidate_tags[index] = nil
    end
  end
  self:_refresh_candidate_tags()
end

function M:_refresh_candidate_tags()
  for index, item in ipairs(self._candidate_tag_items) do
    local tag = self._candidate_tags[index]
    item:set_data(index, tag, false)
  end
end

function M:_select_tag(index)
  local tag = self._candidate_tags[index]
  if not tag or not string.is_valid(tag.text) then
    return
  end
  for _, selected in ipairs(self._selected_tags) do
    if selected.id == tag.id then
      return
    end
  end
  if #self._selected_tags >= selected_tag_limit then
    UIUtil.show_tips_by_text_id("Liuyanban_Tags_Limit", selected_tag_limit)
    return
  end
  self:_remove_tag_from_pool(tag)
  table.insert(self._selected_tags, tag)
  self:_roll_tags(tag.group_id)
  self:_refresh_content()
end

function M:_remove_selected_tag(index)
  local tag = self._selected_tags[index]
  if tag == nil then
    return
  end
  self._pending_delete_tag_index = nil
  table.remove(self._selected_tags, index)
  self:_add_tag_to_pool(tag)
  self:_refresh_content()
end

function M:_refresh_selected_tags()
  self:_ensure_selected_tag_items(#self._selected_tags)
  for index, item in ipairs(self._selected_tag_items) do
    local tag = self._selected_tags[index]
    item:set_data(index, tag, true, self._pending_delete_tag_index == index)
  end
end

function M:_refresh_content()
  self:_refresh_selected_tags()
  UIUtil.set_text(self._txt_count_current, string.format("%s/%s", TextMapFormatUtil.FormatInteger(self._input_comment:CalculateTextUnits(self._comment_content)), TextMapFormatUtil.FormatInteger(self._max_comment_chars)))
end

function M:_on_comment_changed(content)
  self._comment_content = content or ""
  self:_refresh_content()
end

function M:_submit()
  if not player_module:is_local_player_scene_owner() and CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseVisitMessage) then
    CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
    return
  end
  local content = self._comment_content
  if not string.is_valid(content) or string.gsub(content, "%s", "") == "" then
    content = ""
  end
  if content == "" and #self._selected_tags == 0 then
    UIUtil.show_tips_by_text_id("Liuyanban_Input_Empty")
    return
  end
  local max_count = ExcelDataUtil.get_value(typeof(BMessageBoardCfg), 2)
  if CsPlayerVisitModuleUtil.GetPlayerLeaveMessageCount(player_module:get_player_uid()) >= max_count.value then
    UIUtil.show_tips_by_text_id("Market_Message_SendFail_Tip")
    return
  end
  family_comment_module:submit_comment(content, self._selected_tags, function(success)
    if is_null(self.trans) then
      return
    end
    if success then
      self:close_self()
    end
  end)
end

return M
