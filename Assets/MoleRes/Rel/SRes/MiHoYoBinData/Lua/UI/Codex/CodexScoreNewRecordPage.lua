local M = G.Class("CodexScoreNewRecordPage", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreNewRecordPage"
  self._total_count = 0
  self._rare_count = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_tap))
  end
end

function M:_on_tap()
  self.holder:on_new_record_complete()
end

function M:_init_data()
  local changed_data_list = codex_module:get_changed_data_list()
  self._total_count = 0
  self._rare_count = 0
  if is_null(changed_data_list) then
    return
  end
  self._total_count = #changed_data_list
  local extra_data = self:get_extra_data()
  self._rare_count = extra_data ~= nil and (extra_data.rare_count or 0) or 0
end

function M:_refresh_view()
  if is_null(self._txt_content) then
    return
  end
  if self._rare_count > 0 then
    local content1 = UIUtil.get_text_by_id("CodexScore_RecordContent1", self._total_count)
    local content2 = UIUtil.get_text_by_id("CodexScore_RecordContent2", self._rare_count)
    UIUtil.set_text(self._txt_content, content1 .. "\n" .. content2)
  else
    UIUtil.set_text_by_id(self._txt_content, "CodexScore_RecordContent1", self._total_count)
  end
end

return M
