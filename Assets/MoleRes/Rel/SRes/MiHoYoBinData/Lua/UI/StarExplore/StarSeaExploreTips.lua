local M = G.Class("StarSeaExploreTips", G.UIWindow)
local base = G.UIWindow
local auto_close_delay_seconds = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExplore/StarSeaExploreTips"
  self.config.type = EUIType.Tip
end

function M:on_create()
  base.on_create(self)
  self._auto_close_timer = nil
end

function M:on_open()
  base.on_open(self)
  self:_restart_auto_close_timer()
end

function M:on_enable()
  base.on_enable(self)
  if self:_is_scene_switching() then
    self:close_self()
    return
  end
  local data = self:get_extra_data()
  if data then
    self:_set_text(data.textid)
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  self:_stop_auto_close_timer()
  base.on_close(self)
end

function M:on_destroy()
  self:_stop_auto_close_timer()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaSetLoadingState, function(is_loading)
    if is_loading then
      self:_close_on_scene_switch()
    end
  end)
  self:add_lua_listener(lua_event_module.event_type.on_level_prepare, pack(self, M._close_on_scene_switch))
end

function M:_close_on_scene_switch()
  if not self.is_active then
    return
  end
  self:close_self()
end

function M:_is_scene_switching()
  return UIManagerInstance:is_show("UI/Loading/LoadingPage") ~= nil or UIManagerInstance:is_show("UI/Loading/StarExploreLoadingPage") ~= nil
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_restart_auto_close_timer()
  self:_stop_auto_close_timer()
  self._auto_close_timer = CsTimerManagerUtil.StartTimer(auto_close_delay_seconds, function()
    self._auto_close_timer = nil
    self:close_self()
  end)
end

function M:_stop_auto_close_timer()
  if self._auto_close_timer == nil then
    return
  end
  CsTimerManagerUtil.StopTimer(self._auto_close_timer)
  self._auto_close_timer = nil
end

function M:_set_text(textid)
  UIUtil.set_text(self._txt_info, UIUtil.get_text_by_id(textid))
end

return M
