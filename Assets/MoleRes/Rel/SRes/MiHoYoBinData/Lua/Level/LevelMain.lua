level_module = level_module or {}

function level_module:add_event()
  level_module:remove_event()
  self._events = {}
  self._events[EventID.LuaSetLoadingState] = pack(self, self._handle_level_load_finish)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function level_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function level_module:cut_scene(scene_id)
  if scene_id and 0 < scene_id then
    GameSceneUtility.LoadScene(scene_id)
  end
end

function level_module:_handle_level_load_finish(is_loading)
  chat_module:_on_set_loading_state(is_loading)
end

function level_module:is_multi_scene()
  return GameSceneUtility.IsCurrentSceneMultiplayer()
end

function level_module:is_loading()
  return not GameSceneUtility.IsCurrentSceneReady()
end

return level_module or {}
