local M = G.Class("UIBase")

function M:__ctor()
  self.config = {prefab_path = ""}
  self.holder = nil
  self.trans = nil
  self.parent_trans = nil
  self.game_obj = nil
  self.rect_trans = nil
  self.binder = nil
  self._has_binder = false
  self._handles = {}
  self.is_active = false
  self._is_play_anim = false
  self._extra_data = nil
  self._event_funcs = {}
  self._lua_listener = {}
  self._is_hide_close_listener = true
  self.cname_hash = CsUIUtil.GetHashCode(self.__cname)
end

function M:__delete()
  self:on_destroy()
  self:_clear()
  self:_inner_destroy()
end

function M:set_gameobject(go)
  self.game_obj = go
  self.trans = go.transform
  self.rect_trans = UIUtil.find_rect_trans(self.trans)
  self.binder = UIUtil.find_cmpt(self.trans, nil, typeof(MonoViewBinder))
  self._has_binder = not is_null(self.binder)
  if self._has_binder then
    self.binder:Init()
  end
end

function M:init()
end

function M:on_create()
  self:_setup_binder_fields()
  self:register_events()
  if self._has_binder then
    self.binder:AddAnimationEvent(function(key_tag)
      self:on_animation_event(key_tag)
    end)
  end
end

function M:on_enable()
  self:enable_update(true)
  if self._is_hide_close_listener then
    self:open_lua_listener()
  end
end

function M:on_disable()
  self:enable_update(false)
  if self._is_hide_close_listener then
    self:close_lua_listener()
  end
end

function M:on_destroy()
end

function M:_clear()
  self:unregister_events()
  self:clear_all_lua_listener()
  if self._has_binder then
    self.binder:Clear()
  end
end

function M:_inner_destroy()
  local go = self.game_obj
  table.clear(self)
  if not is_null(go) then
    UIUtil.destroy_go(go)
    self.game_obj = nil
  end
  collectgarbage("collect")
end

function M:enable_update(enable)
end

function M:set_active(active)
  if self.is_active == active then
    return
  end
  if active then
    self:_inner_set_active(true)
    self:on_enable()
    self:play_enter_anim()
  else
    self:play_exit_anim()
  end
end

function M:play_enter_anim()
  if self._has_binder then
    self._is_play_anim = true
    self.binder:PlayEnterAnim(function()
      self._is_play_anim = false
      self:enter_anim_call_back()
    end)
  else
    self:enter_anim_call_back()
  end
end

function M:play_exit_anim()
  if self._has_binder then
    self._is_play_anim = true
    self.binder:PlayExitAnim(function()
      self._is_play_anim = false
      self:exit_anim_call_back()
    end)
  else
    self:exit_anim_call_back()
  end
end

function M:enter_anim_call_back()
end

function M:exit_anim_call_back()
  self:_inner_set_active(false)
  self:on_disable()
end

function M:_inner_set_active(active)
  self.is_active = active
  self.game_obj:SetActive(active)
end

function M:set_extra_data(data)
  self._extra_data = data
end

function M:get_extra_data()
  return self._extra_data
end

function M:get_load_proxy()
  if not is_null(self.holder) then
    return self.holder:get_load_proxy()
  end
  Logger.LogError("get_load_proxy error!!! lua class name = " .. self.__cname)
  return nil
end

function M:get_prefab_load_proxy()
  if not is_null(self.holder) then
    return self.holder:get_prefab_load_proxy()
  end
  Logger.LogError("get_prefab_load_proxy error!!! lua class name = " .. self.__cname)
  return nil
end

function M:_setup_binder_fields()
  if self._has_binder then
    for _, v in pairs(self.binder.fields) do
      self[v.name] = v:GetObject()
    end
  end
end

function M:bind_callback(obj, callback)
  if self._has_binder then
    self.binder:BindViewCallback(obj, callback)
  end
end

function M:register_events()
end

function M:unregister_events()
  for k, v in pairs(self._event_funcs) do
    EventCenter.LuaRemoveListener(k, v)
  end
  self._event_funcs = {}
end

function M:add_evt_listener(event_id, func)
  if event_id == nil then
    Logger.LogError("event_id is nil")
    return
  end
  if self._event_funcs[event_id] ~= nil then
    Logger.LogError("已绑定相同事件，event_id:" .. event_id)
    return
  end
  
  local function add_func(p1, ...)
    if self._is_hide_close_listener then
      if self.is_active then
        func(p1, ...)
      end
    else
      func(p1, ...)
    end
  end
  
  self._event_funcs[event_id] = add_func
  EventCenter.LuaAddListener(event_id, add_func)
end

function M:remove_evt_listener(event_id)
  local func = self._event_funcs[event_id]
  if func == nil then
    Logger.LogError("事件已注销，event_id:" .. event_id)
    return
  end
  EventCenter.LuaRemoveListener(event_id, func)
end

function M:on_animation_event(key_tag)
end

function M:add_lua_listener(main_id, sub_id, callback)
  if callback == nil then
    return
  end
  if lua_event_module:add_sub_listener(main_id, sub_id, callback) then
    table.insert(self._lua_listener, {main_id, sub_id})
  end
end

function M:clear_all_lua_listener()
  if self._lua_listener == nil then
    return
  end
  for _, v in pairs(self._lua_listener) do
    lua_event_module:remove_listener(v[1], v[2])
  end
  self._lua_listener = {}
end

function M:close_lua_listener()
  for _, v in pairs(self._lua_listener) do
    lua_event_module:close_listener(v[1], v[2])
  end
end

function M:open_lua_listener()
  for _, v in pairs(self._lua_listener) do
    lua_event_module:open_listener(v[1], v[2])
  end
end

function M:play_anim(anim_name, callback)
  if not self._has_binder or not string.is_valid(anim_name) then
    return
  end
  self._is_play_anim = true
  self.binder:PlayAnimation(anim_name, function()
    self._is_play_anim = false
    if callback then
      callback()
    end
  end)
end

function M:is_play_anim()
  return self._is_play_anim
end

return M
