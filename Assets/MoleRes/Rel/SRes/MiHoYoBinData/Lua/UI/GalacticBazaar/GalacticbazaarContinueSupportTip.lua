local M = G.Class("GalacticbazaarContinueSupportTip", G.UIWindow)
local base = G.UIWindow
local AUTO_CLOSE_SEC = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticbazaarContinueSupportTip"
  self.config.type = EUIType.Tip
  self._close_timer = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  self:_refresh(self:get_extra_data())
end

function M:on_disable()
  base.on_disable(self)
  self._close_timer = nil
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:refresh_count(count)
  self:_refresh(count)
end

function M:_refresh(count)
  UIUtil.set_text_by_id(self._txt_support_num, "CHAIN_CHEER_TEXT", count or 0)
  self._close_timer = AUTO_CLOSE_SEC
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._close_timer then
    return
  end
  self._close_timer = self._close_timer - deltaTime
  if self._close_timer <= 0 then
    self._close_timer = nil
    self:close_self()
  end
end

return M
