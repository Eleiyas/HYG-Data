local M = G.Class("MiTaiOrderWelcomePanel", "UI/MiTai/MiTaiBasePanel")
local base = M.super

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTai/MiTaiOrderWelcomePanel"
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

return M
