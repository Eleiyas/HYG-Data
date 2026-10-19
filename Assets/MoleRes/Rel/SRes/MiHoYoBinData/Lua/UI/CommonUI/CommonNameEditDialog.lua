local M = G.Class("CommonNameEditDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonNameEditDialog"
  self.config.type = EUIType.Dialog
  self._confirm_callback = nil
  self._title_txt = ""
  self._info_place_holder = ""
  self._init_input_txt = ""
  self._confirm_btn_text = ""
  self._changed_text = ""
  self._max_char_limit = 20
  self._txt_character_limit_str = ""
  self._empty_txt_tips = ""
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._edit_input.text = ""
  local extra_data = self:get_extra_data()
  self._confirm_callback = extra_data.confirm_callback
  self._confirm_btn_text = extra_data.confirm_btn_text
  self._max_char_limit = tonumber(extra_data.max_char_limit) or 20
  self._info_place_holder = extra_data.place_holder or UIUtil.get_text_by_id("CommonInfoEditDialog_Character_Number", self._max_char_limit)
  self._title_txt = extra_data.title or ""
  self._txt_character_limit_str = extra_data.txt_character_limit or UIUtil.get_text_by_id("CommonInfoEditDialog_Character_Limit")
  self._empty_txt_tips = extra_data.empty_txt_tips or UIUtil.get_text_by_id("CommonInfoEditDialog_Prompt_Tip")
  self._init_input_txt = extra_data.init_input_txt or ""
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_callback(self._edit_input, function(str)
    UIUtil.set_active(self._trans_character_limit_tips, CsUIUtil.GetStringCount(str) > self._max_char_limit)
  end)
  self:bind_close_btn(self._btn_bg_close)
end

function M:_refresh_view()
  UIUtil.set_text(self._txt_title, self._title_txt)
  UIUtil.set_text(self._txt_place_holder, self._info_place_holder)
  UIUtil.set_text(self._txt_confirm_txt, self._confirm_btn_text)
  if self._txt_character_limit_str ~= "" then
    UIUtil.set_text(self._txt_character_limit, self._txt_character_limit_str)
  end
  self._edit_input.maxCharacters = self._max_char_limit
  if self._init_input_txt ~= "" then
    self._edit_input.text = self._init_input_txt
  end
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_confirm, pack(self, M._confirm_click))
end

function M:_confirm_click()
  local final_str = self._edit_input.text
  if CsUIUtil.GetStringCount(final_str) > self._max_char_limit then
    return
  end
  if not string.is_valid(final_str) then
    UIUtil.show_tips(self._empty_txt_tips)
    return
  end
  if self._confirm_callback then
    self._confirm_callback(final_str)
  end
  self:close_self()
end

return M
