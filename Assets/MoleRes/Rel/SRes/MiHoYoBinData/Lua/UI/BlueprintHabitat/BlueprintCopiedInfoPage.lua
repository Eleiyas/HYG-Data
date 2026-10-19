local base_cls = require("UI/BlueprintHabitat/BlueprintInfoPageBase")
local M = G.Class("BlueprintCopiedInfoPage", base_cls)
local base = base_cls

function M:init()
  base.init(self)
  self._btn_more = nil
  self._btn_edit = nil
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
  self:add_evt_listener(EventID.WorldEdit.LuaUI.CopiedBlueprintDataChanged, pack(self, M._on_data_changed))
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

function M:_domain()
  return new_blueprint_module.BLUEPRINT_DOMAIN.copied
end

function M:_type_state()
  return new_blueprint_module.INFO_TYPE_STATE.copied_detail
end

function M:_read_key_from_extra(extra)
  return extra and extra.bp_guid or 0
end

function M:_key_of(entry)
  return entry.BpGuid
end

function M:_get_sorted_list()
  return new_blueprint_module:get_copied_sorted_list()
end

function M:_refresh_title_and_extra()
  local data = self:_cur_entry()
  if data == nil then
    return
  end
  UIUtil.set_text(self._txt_name, data.Name or "")
  if not_null(self._txt_like_num) then
    UIUtil.set_text(self._txt_like_num, TextMapFormatUtil.FormatAbbreviation(data.LikeCount or 0))
  end
  if not_null(self._txt_paste_num) then
    UIUtil.set_text(self._txt_paste_num, TextMapFormatUtil.FormatAbbreviation(data.CopyCount or 0))
  end
end

function M:_bind_extra_callbacks()
  base._bind_extra_callbacks(self)
  if not_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_btn_more_click))
  end
  if not_null(self._btn_edit) then
    self:bind_callback(self._btn_edit, pack(self, M._on_btn_edit_click))
  end
end

function M:_on_btn_more_click()
  local pos = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1)
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Blueprint_UI_007"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_delete)
    },
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

function M:_on_menu_delete()
  if self._cur_key == 0 then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Blueprint_DeleteCopiedConfirm"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(pack(self, M._confirm_delete))
  popup:show()
end

function M:_confirm_delete()
  if self._cur_key == 0 then
    return
  end
  new_blueprint_module:delete_copied_blueprint(self._cur_key)
end

function M:_on_menu_report()
  local entry = self:_cur_entry()
  if entry == nil then
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

function M:_on_btn_edit_click()
end

return M
