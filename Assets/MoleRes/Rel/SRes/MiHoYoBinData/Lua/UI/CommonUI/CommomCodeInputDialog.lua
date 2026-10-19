local M = G.Class("CommomCodeInputDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/Dialog/CommomCodeInputDialog"
  self.config.type = EUIType.Dialog
  self._confirm_callback = nil
  self._title_txt = ""
  self._placeholder_txt = ""
  self._max_char_limit = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data() or {}
  self._confirm_callback = extra_data.confirm_callback
  self._title_txt = extra_data.title or ""
  self._placeholder_txt = extra_data.placeholder or ""
  self._max_char_limit = tonumber(extra_data.max_char_limit) or 0
  self:_refresh_view()
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_callback(self._input_field, pack(self, M._on_input_changed))
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_popup)
  self:bind_close_btn(self._btn_bg)
  self:bind_callback(self._btn_confim, pack(self, M._on_btn_confim_click))
  self:bind_callback(self._btn_paste, pack(self, M._on_btn_paste_click))
  self:bind_callback(self._btn_del, pack(self, M._on_btn_del_click))
end

function M:_refresh_view()
  if self._title_txt ~= "" then
    UIUtil.set_text(self._txt_title, self._title_txt)
  end
  if self._placeholder_txt ~= "" then
    UIUtil.set_text(self._txt_placeholder, self._placeholder_txt)
  end
  self._input_field.text = ""
  if self._max_char_limit > 0 then
    self._input_field.maxCharacters = self._max_char_limit
  end
  self:_refresh_interactable()
end

function M:_refresh_interactable()
  local has_text = string.is_valid(self._input_field.text)
  if not_null(self._btn_confim) then
    self._btn_confim.interactable = has_text
  end
  UIUtil.set_active(self._btn_del, has_text)
end

function M:_on_input_changed()
  self:_refresh_interactable()
end

function M:_on_btn_paste_click()
  local clipboard_text = CS.UnityEngine.GUIUtility.systemCopyBuffer
  if not string.is_valid(clipboard_text) then
    UIUtil.show_tips_by_text_id("Common_ClipboardEmpty")
    return
  end
  self._input_field.text = clipboard_text
  self:_refresh_interactable()
end

function M:_on_btn_del_click()
  self._input_field.text = ""
  self:_refresh_interactable()
end

function M:_on_btn_confim_click()
  local code = self._input_field.text
  if not string.is_valid(code) then
    return
  end
  if self._confirm_callback and self._confirm_callback(code) == false then
    return
  end
  self:close_self()
end

return M
