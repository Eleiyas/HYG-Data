local M = G.Class("GoodmanInterviewBeginTips", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GoodmanInterview/GoodmanInterviewBeginTips"
  self.config.type = EUIType.Tip
  self._show_time = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  self._show_time = extra and extra.duration or 0
  local topic = extra and extra.topic or ""
  if string.is_valid(topic) then
    UIUtil.set_text_by_id(self._txt_desc, "GoodmanInterview_TipsDesc", topic)
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._show_time > 0 then
    self._show_time = self._show_time - deltaTime
    if self._show_time <= 0 then
      self:close_self()
    end
  end
end

return M
