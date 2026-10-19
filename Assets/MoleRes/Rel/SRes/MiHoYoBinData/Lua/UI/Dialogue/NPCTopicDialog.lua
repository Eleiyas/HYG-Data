local M = G.Class("NPCTopicDialog", G.UIWindow)
local base = G.UIWindow
local InputFieldExType = typeof(CS.miHoYo.HYG.UI.InputFieldEx)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Dialogue/NPCTopicDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self._npc_id = 0
  self._topic_id = 0
  self._confirm_callback = nil
  self._cancel_callback = nil
  self:_ensure_view_refs()
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaCloseNpcTopicDialog, pack(self, M.close_self))
end

function M:_ensure_view_refs()
  if is_null(self._inputfield) and not_null(self.trans) then
    self._inputfield = UIUtil.find_cmpt(self.trans, nil, InputFieldExType)
  end
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_lv1_confirm, pack(self, M._on_confirm_click))
  self:bind_callback(self._btn_lv1_concel, pack(self, M._on_cancel_click))
end

function M:on_enable()
  base.on_enable(self)
  self:_parse_extra_data()
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
  self._topic_id = 0
  self._npc_id = 0
  self._cancel_callback = nil
  self._confirm_callback = nil
end

function M:_parse_extra_data()
  local data = self:get_extra_data()
  if is_null(data) then
    Logger.LogError("_parse_extra_data data is null")
    return
  end
  self._topic_id = tonumber(data.topic_id) or 0
  self._npc_id = tonumber(data.npc_id) or 0
  self._cancel_callback = data.cancel_cb
  self._confirm_callback = data.confirm_cb
end

function M:_refresh_ui()
  self:_ensure_view_refs()
  local topic_id = tonumber(self._topic_id) or 0
  local topic_cfg = CsExcelDataUtil.GetPlayerInputTopicCfg(topic_id)
  if topic_cfg == nil or (topic_cfg.id or 0) == 0 then
    if not_null(self._txt_title) then
      self._txt_title.text = "话题 " .. tostring(topic_id)
    end
    return
  end
  if not_null(self._txt_title) then
    self._txt_title.text = UIUtil.get_text_by_id("DailyConversation_PlayerLikeChat_Title") or ""
  end
  self:_apply_input_placeholder(topic_cfg)
  self:_bind_button_localization()
end

function M:_apply_input_placeholder(topic_cfg)
  if is_null(self._inputfield) or topic_cfg == nil then
    return
  end
  self._inputfield.text = ""
  local placeholder = UIUtil.find_cmpt(self._inputfield.transform, "TextArea/Placeholder", typeof(TextEx))
  if not_null(placeholder) then
    local chat_place_holder = self:_get_likechat_content(self._topic_id)
    placeholder.text = chat_place_holder or ""
  end
end

function M:_bind_button_localization()
  if not_null(self._btn_lv1_confirm) then
    local txt_confirm = UIUtil.find_cmpt(self._btn_lv1_confirm, nil, typeof(TextEx))
    if not_null(txt_confirm) then
      local confirm_txt = UIUtil.get_text_by_id("DailyConversation_PlayerLikeChat_Confirm") or ""
      txt_confirm.text = confirm_txt
    end
  end
  if not_null(self._btn_lv1_concel) then
    local txt_cancel = UIUtil.find_cmpt(self._btn_lv1_concel, nil, typeof(TextEx))
    if not_null(txt_cancel) then
      local cancel_txt = UIUtil.get_text_by_id("DailyConversation_PlayerLikeChat_Cancel") or ""
      txt_cancel.text = cancel_txt
    end
  end
end

local suffixes = {
  "Drink",
  "Food",
  "Song",
  "Book",
  "Movie",
  "Anime"
}

function M:_get_likechat_content(topic_id)
  local likechat_suffix = suffixes[topic_id] or ""
  Logger.Log("_get_likechat_content" .. tostring(topic_id))
  local likechat_content_id = "DailyConversation_PlayerLikeChat_" .. likechat_suffix
  return UIUtil.get_text_by_id(likechat_content_id)
end

function M:_get_input_content()
  self:_ensure_view_refs()
  if not_null(self._inputfield) then
    local content = self._inputfield.text or ""
    content = string.gsub(content, "​", "")
    return content
  end
  return ""
end

function M:_on_confirm_click()
  local content = self:_get_input_content()
  if self._confirm_callback then
    self._confirm_callback(content)
  end
end

function M:_on_cancel_click()
  self:close_self()
  if self._cancel_callback then
    self._cancel_callback()
  end
end

return M
