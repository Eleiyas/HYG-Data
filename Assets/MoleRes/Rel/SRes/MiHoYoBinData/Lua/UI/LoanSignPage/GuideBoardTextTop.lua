local M = G.Class("GuideBoardTextTop", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LoanSignPage/GuideBoardTextTop"
  self.config.type = EUIType.Scene
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self:create_text(data)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaCloseUITexText, function()
    UIUtil.set_active(self._obj_txt, false)
  end)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:create_text(data)
  if data and data.text and data.guid then
    UIUtil.set_active(self.game_obj, true)
    CsTextTextureUtil.SetTextCopyable(self._obj_txt, data.guid)
    UIUtil.set_active(self._obj_txt, true)
    UIUtil.set_text(self._txt_ex, data.text)
    CsTextTextureUtil.SaveTextTexTure(self._obj_txt, data.guid)
  end
end

return M
