local M = G.Class("TalkRabbitOptionItem", G.UIBase)
local base = G.UIBase
local translate_util = require("Common/TranslateUtil")

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  if self._tog_option then
    self:bind_callback(self._tog_option, pack(self, M._on_tog_option_value_changed))
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:refresh(word, selected, click_callback)
  self._word = word
  self._click_callback = click_callback
  translate_util.apply_with_translation(word, translate_util.SCENE_LLM_TEXT, function(display_text)
    UIUtil.set_text(self._txt_name, display_text)
  end, function()
    return not is_null(self._txt_name) and self._word == word
  end)
  self:apply_selected(selected)
end

function M:apply_selected(selected)
  if self._tog_option then
    self._tog_option.isOnValue = selected == true
  end
end

function M:_on_tog_option_value_changed()
  if self._click_callback and self._word then
    self._click_callback(self._word)
  end
end

return M
