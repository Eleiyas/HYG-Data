local base_cls = require("UI/BlueprintHabitat/BlueprintInfoPageBase")
local M = G.Class("BlueprintSharedInfoPage", base_cls)
local base = base_cls

function M:init()
  base.init(self)
  self._shared_entry_list = nil
  self._btn_more = nil
  self._btn_upload_corner_again = nil
end

function M:on_before_close()
  base.on_before_close(self)
  if not CsNewBlueprintModuleUtil.IsNull() then
    CsNewBlueprintModuleUtil.ClearSharedPreview()
  end
end

function M:_type_state()
  local state = new_blueprint_module.INFO_TYPE_STATE
  local entry = self:_cur_entry()
  if self:_is_created_by_self(entry) then
    return state.custom_repost
  end
  local already_copied = entry ~= nil and entry.IsCopied == true
  if not CsNewBlueprintModuleUtil.IsNull() then
    already_copied = already_copied or false
  end
  return already_copied and state.copied_detail or state.shared_import
end

function M:_domain()
  return new_blueprint_module.BLUEPRINT_DOMAIN.shared
end

function M:_read_key_from_extra(extra)
  local ok, data = CsNewBlueprintModuleUtil.TryGetSharedBlueprintData()
  return ok and data and data.BpGuid or 0
end

function M:_key_of(entry)
  return entry and entry.BpGuid or 0
end

function M:_is_valid_key(key)
  if CsNewBlueprintModuleUtil.IsNull() then
    return false
  end
  local ok = CsNewBlueprintModuleUtil.TryGetSharedBlueprintData()
  return ok == true
end

function M:_get_sorted_list()
  local ok, data = CsNewBlueprintModuleUtil.TryGetSharedBlueprintData()
  if not ok or data == nil then
    self._shared_entry_list = {}
    return self._shared_entry_list
  end
  self._shared_entry_list = {data}
  return self._shared_entry_list
end

function M:_refresh_title_and_extra()
  local entry = self:_cur_entry()
  if entry == nil then
    return
  end
  UIUtil.set_text(self._txt_name, entry.Name or "")
  UIUtil.set_text(self._txt_like_num, TextMapFormatUtil.FormatAbbreviation(entry.LikeCount or 0))
  UIUtil.set_text(self._txt_paste_num, TextMapFormatUtil.FormatAbbreviation(entry.CopyCount or 0))
end

function M:_bind_extra_callbacks()
  base._bind_extra_callbacks(self)
  if not_null(self._btn_import) then
    self:bind_callback(self._btn_import, pack(self, M._on_btn_import_click))
  end
  if not_null(self._btn_edit) then
    self:bind_callback(self._btn_edit, pack(self, M._on_btn_edit_click))
  end
  if not_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_btn_more_click))
  end
  if not_null(self._btn_upload_corner_again) then
    self:bind_callback(self._btn_upload_corner_again, pack(self, M._on_btn_upload_corner_click))
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.WorldEdit.LuaUI.CopyBlueprintResult, pack(self, M._on_copy_result))
end

function M:_on_copy_result(arg)
  if (tonumber(arg) or 0) ~= 0 then
    return
  end
  self:_refresh_view()
end

function M:_on_btn_import_click()
  new_blueprint_module:try_copy_shared_blueprint()
end

function M:_on_btn_edit_click()
end

function M:_on_btn_more_click()
  local entry = self:_cur_entry()
  if entry == nil or self:_is_created_by_self(entry) then
    return
  end
  local pos = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1)
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Blueprint_ReportBlueprint"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_report)
    }
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = pos,
    state = 1,
    menus = menus
  })
end

function M:_on_menu_report()
  local entry = self:_cur_entry()
  if entry == nil or self:_is_created_by_self(entry) then
    return
  end
  report_module:open_report_page({
    target = report_module.report_target.blueprint_custom,
    target_uid = self:_creator_uid_of(entry),
    target_message = entry.Name or "",
    file_key = entry.ImageKey or "",
    author_bp_guid = entry.AuthorBpGuid or 0,
    content_version = new_blueprint_module:get_content_version(entry)
  })
end

function M:_on_btn_upload_corner_click()
  local entry = self:_cur_entry()
  local data = new_blueprint_module:find_custom_data_by_share_code(entry and entry.BpShareCode)
  local ctx = new_blueprint_module:try_make_little_corner_post_ctx(data or entry)
  if ctx == nil then
    return
  end
  little_corner_module:open_post_with_blueprint(ctx)
end

return M
