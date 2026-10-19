local M = G.Class("RabbitTabletopPrepareTip", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopPrepareTip"
  self.config.type = EUIType.Tip
  self._show_time = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  local cfg = ExcelDataUtil.get_value(typeof(BUnoConstantCfg), 1)
  self._show_time = cfg.readystarttips
end

function M:on_disable()
  base.on_disable(self)
  local data = self:get_extra_data()
  if data and data.on_complete then
    data.on_complete()
    data.on_complete = nil
  end
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
