local M = G.Class("RabbitTabletopWinerTip", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopWinerTip"
  self.config.type = EUIType.Tip
  self._show_time = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  if data and data.winner_name then
    UIUtil.set_text(self._txt_content, data.winner_name)
  end
  self._show_time = 3
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
