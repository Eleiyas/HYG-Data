local M = G.Class("LocalizationManager")

function M:__ctor()
  self._text_map_util = TextMapUtils
end

function M:__delete()
  if self:_init_manager() and self._pack_event then
    self._loc_manager:RemoveLanChangeListener(self._pack_event)
  end
end

function M:get_text_by_id(text_map_id, ...)
  if self._text_map_util and string.is_valid(text_map_id) then
    return self._text_map_util.Get(text_map_id, ...)
  end
  return nil
end

function M:handle_text(text, ...)
  if self._text_map_util and string.is_valid(text) then
    return self._text_map_util.HandleText(text, ...)
  end
  return text
end

function M:get_cur_lan_type()
  if self:_init_manager() then
    return self._loc_manager:GetCurLanguageType()
  end
end

function M:_init_manager()
  if is_null(self._loc_manager) then
    self._loc_manager = CsLocalizationManagerUtil
  end
  if is_null(self._loc_manager) then
    return false
  end
  return true
end

function M:get_all_lan_config()
  if self:_init_manager() then
    return self._loc_manager.GetAllLanguageConfig()
  end
  return nil
end

function M:get_cur_lan_config()
  if self:_init_manager() then
    return self._loc_manager.GetCurLanguageConfig()
  end
  return nil
end

function M:change_language(type)
  if self:_init_manager() then
    self._loc_manager.ChangeLanguage(type)
  end
end

function M:get_all_voice_lan_config()
  if self:_init_manager() then
    return self._loc_manager.GetAllVoiceLanguageConfig()
  end
  return nil
end

function M:get_cur_voice_lan_config()
  if self:_init_manager() then
    return self._loc_manager.GetCurVoiceLanguageConfig()
  end
  return nil
end

function M:change_voice_language(type)
  if self:_init_manager() then
    self._loc_manager.ChangeVoiceLanguage(type)
  end
end

return M
