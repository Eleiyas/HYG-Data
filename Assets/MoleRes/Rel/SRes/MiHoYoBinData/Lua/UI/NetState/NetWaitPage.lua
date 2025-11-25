local M = G.Class("NetWaitPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NetState/NetWaitPage"
  self.config.type = EUIType.Tip
  self.config.input_penetrate = false
  self.config.destroy_when_light_refresh = false
end

function M:on_create()
  base.on_create(self)
end

function M:register_events()
  self:add_evt_listener(EventID.luaCloseNetWaitPage, pack(self, M.close_self))
end

function M:on_enable()
  base.on_enable(self)
  if self._extra_data and self._extra_data.onEnable then
    self._extra_data.onEnable()
    self._extra_data.onEnable = nil
  end
  self:_init_img_style()
end

function M:_init_img_style()
  local cur_time = 9
  if DayTimeUtil.Instance then
    cur_time = DayTimeUtil.Instance:GetTime()
  end
  if 6 <= cur_time and cur_time <= 18 then
    UIUtil.set_image_color(self._bg, "#75A437FF")
  else
    UIUtil.set_image_color(self._bg, "#11121EFF")
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  if not self.is_active then
    return
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:handle_input_action(action)
end

return M
