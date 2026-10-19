local M = G.Class("GeLianMarketContainerPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._page_service = nil
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._page_service = context and context.page_service or nil
end

function M:on_destroy()
  if self._page_service ~= nil then
    self._page_service:withdraw_owner(self)
  end
  self._page_service = nil
  base.on_destroy(self)
end

function M:provide_service_port(port_id, exports)
  if self._page_service == nil then
    return false
  end
  return self._page_service:provide(port_id, self, exports)
end

return M
