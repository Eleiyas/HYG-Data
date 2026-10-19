local M = G.Class("RabbitTabletopStartTip", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopStartTip"
  self.config.type = EUIType.Tip
  self._show_time = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  self._show_time = extra and extra.duration or 2
  self._on_close_cb = extra and extra.on_close or nil
  UIUtil.set_text(self._txt_tips, extra and extra.tips or "")
end

function M:on_close()
  base.on_close(self)
  if self._on_close_cb then
    local cb = self._on_close_cb
    self._on_close_cb = nil
    cb()
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
