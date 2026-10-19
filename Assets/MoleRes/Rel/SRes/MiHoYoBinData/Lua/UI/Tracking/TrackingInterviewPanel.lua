local M = G.Class("TrackingInterviewPanel", G.UIPanel)
local base = G.UIPanel
local THEME_ITEM_CLASS = "UI/Tracking/InterviewThemeItem"
local BEGIN_TIPS_CLASS = "UI/GoodmanInterview/GoodmanInterviewBeginTips"
local BEGIN_TIPS_DURATION = 2

function M:init()
  base.init(self)
  self._theme_item = nil
  self._theme_topic = nil
  self._npc_config_id = 0
  self._begin_tips_token = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_interrupt, pack(self, M._on_btn_interrupt_click))
  UIUtil.set_text_by_id(self._txt_interrupt, "GoodmanInterview_End")
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaShowInterviewPanel, pack(self, M.refresh))
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
end

function M:refresh()
  self:_refresh_npc()
  self:_refresh_theme()
  self:_try_show_begin_tips()
end

function M:_refresh_npc()
  local npc_config_id = GameplayUtilities_LlmaiNpc.InterviewGetNpcConfigId()
  if npc_config_id == self._npc_config_id then
    return
  end
  self._npc_config_id = npc_config_id
  local npc_cfg = 0 < npc_config_id and ExcelDataUtil.get_value(typeof(BNpcCfg), npc_config_id) or nil
  if not npc_cfg then
    UIUtil.set_text(self._txt_title, "")
    return
  end
  UIUtil.set_text(self._txt_title, npc_cfg.name)
  UIUtil.set_image(self._img_npc, npc_cfg.iconnamesmall, self:get_load_proxy())
end

function M:_refresh_theme()
  local topic = GameplayUtilities_LlmaiNpc.InterviewGetTopic()
  local is_show = string.is_valid(topic)
  if is_show and self._theme_item == nil then
    self._theme_item = self:add_panel(THEME_ITEM_CLASS, self._condition_list_binder:AddItem())
    self._trans_interrupt:SetAsLastSibling()
  end
  if self._theme_item == nil then
    return
  end
  self._theme_item:set_active(is_show)
  if not is_show or topic == self._theme_topic then
    return
  end
  self._theme_topic = topic
  self._theme_item:refresh("GoodmanInterview_Theme", topic)
end

function M:_try_show_begin_tips()
  local token = GameplayUtilities_LlmaiNpc.InterviewGetSessionToken()
  if not string.is_valid(token) or token == self._begin_tips_token then
    return
  end
  self._begin_tips_token = token
  UIManagerInstance:open(BEGIN_TIPS_CLASS, {
    duration = BEGIN_TIPS_DURATION,
    topic = GameplayUtilities_LlmaiNpc.InterviewGetTopic()
  })
end

function M:_on_btn_interrupt_click()
  GameplayUtilities_LlmaiNpc.InterviewRequestEnd()
end

return M
