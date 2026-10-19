local base_cls = require("UI/BlueprintHabitat/BlueprintInfoPageBase")
local M = G.Class("BlueprintCustomInfoPage", base_cls)
local base = base_cls

function M:init()
  base.init(self)
  self._btn_more = nil
  self._btn_share = nil
  self._btn_upload_corner = nil
  self._btn_upload_corner_again = nil
  self._txt_like_num = nil
  self._txt_paste_num = nil
end

function M:on_enable()
  base.on_enable(self)
  local data = self:_cur_entry()
  if data ~= nil then
    new_blueprint_module:refresh_stat_by_share_code(self:_domain(), data.BpShareCode)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.WorldEdit.LuaUI.NewBlueprintDataChanged, pack(self, M._on_data_changed))
end

function M:_on_data_changed(arg)
  self._sorted_list = self:_get_sorted_list()
  local idx = self:_find_index_by_key(self._cur_key)
  if idx == 0 then
    self:close_self()
    return
  end
  self._cur_index = idx
  self:_refresh_view()
end

function M:_type_state()
  local data = self:_cur_entry()
  local state = new_blueprint_module.INFO_TYPE_STATE
  if new_blueprint_module:is_under_review(data) then
    return state.under_review
  end
  if new_blueprint_module:has_shared_xhs_post(data) then
    return state.custom_repost
  end
  return state.custom_detail
end

function M:_domain()
  return new_blueprint_module.BLUEPRINT_DOMAIN.custom
end

function M:_read_key_from_extra(extra)
  return extra and extra.bp_guid or 0
end

function M:_key_of(entry)
  return entry.BpGuid
end

function M:_get_sorted_list()
  if self:_is_from_little_corner_post() then
    local data = new_blueprint_module:get_custom_data(self._cur_key)
    return data ~= nil and {data} or {}
  end
  return new_blueprint_module:get_custom_sorted_list()
end

function M:_is_from_little_corner_post()
  local extra = self._extra_data
  return extra ~= nil and extra.page_source == new_blueprint_module.INFO_PAGE_SOURCE.little_corner_post
end

function M:_refresh_title_and_extra()
  self:_refresh_more_btn_visible()
  local data = self:_cur_entry()
  if data == nil then
    return
  end
  UIUtil.set_text(self._txt_name, data.Name)
  self:_refresh_social_counts(data)
end

function M:_refresh_more_btn_visible()
  if not_null(self._btn_more) then
    UIUtil.set_active(self._btn_more, not self:_is_from_little_corner_post())
  end
end

function M:_bind_extra_callbacks()
  if not_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_btn_more_click))
  end
  if not_null(self._btn_share) then
    self:bind_callback(self._btn_share, pack(self, M._on_btn_share_click))
  end
  if not_null(self._btn_upload_corner) then
    self:bind_callback(self._btn_upload_corner, pack(self, M._on_btn_upload_corner_click))
  end
  if not_null(self._btn_upload_corner_again) then
    self:bind_callback(self._btn_upload_corner_again, pack(self, M._on_btn_upload_corner_click))
  end
end

function M:_refresh_social_counts(data)
  if not_null(self._txt_like_num) then
    UIUtil.set_text(self._txt_like_num, TextMapFormatUtil.FormatAbbreviation(data.LikeCount or 0))
  end
  if not_null(self._txt_paste_num) then
    UIUtil.set_text(self._txt_paste_num, TextMapFormatUtil.FormatAbbreviation(data.CopyCount or 0))
  end
end

function M:_on_btn_more_click()
  local pos = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1)
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Blueprint_UI_006"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_rename)
    },
    {
      desc = UIUtil.get_text_by_id("Blueprint_UI_007"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_delete)
    }
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = pos,
    state = 1,
    menus = menus
  })
end

function M:_on_menu_rename()
  local data = self:_cur_entry()
  if data == nil then
    return
  end
  local edit_data = {
    title = UIUtil.get_text_by_id("Blueprint_UI_014"),
    confirm_callback = pack(self, M._confirm_rename),
    confirm_btn_text = UIUtil.get_text_by_id("Common_Yes"),
    init_input_txt = data.Name or "",
    max_char_limit = 20
  }
  common_ui_module:show_name_edit_dialog(edit_data)
end

function M:_confirm_rename(new_name)
  if self._cur_key == 0 then
    return
  end
  CsNewBlueprintModuleUtil.RenameNewBlueprint(self._cur_key, new_name)
end

function M:_on_menu_delete()
  if self._cur_key == 0 then
    return
  end
  local data = self:_cur_entry()
  local content
  if new_blueprint_module:has_shared_xhs_post(data) then
    content = UIUtil.get_text_by_id("Blueprint_DeleteWithPostConfirm")
  end
  if not string.is_valid(content) then
    content = UIUtil.get_text_by_id("Blueprint_UI_015")
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(content, UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(pack(self, M._confirm_delete))
  popup:show()
end

function M:_confirm_delete()
  if self._cur_key == 0 then
    return
  end
  CsNewBlueprintModuleUtil.DeleteNewBlueprint(self._cur_key)
end

function M:_on_btn_share_click()
end

function M:_on_btn_upload_corner_click()
  if self:_is_from_little_corner_post() then
    self:close_self()
    return
  end
  local ctx = new_blueprint_module:try_make_little_corner_post_ctx(self:_cur_entry())
  if ctx == nil then
    return
  end
  little_corner_module:open_post_with_blueprint(ctx)
end

return M
