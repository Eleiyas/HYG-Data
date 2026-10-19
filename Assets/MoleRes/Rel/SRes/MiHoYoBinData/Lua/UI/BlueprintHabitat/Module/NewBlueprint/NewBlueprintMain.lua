new_blueprint_module = new_blueprint_module or {}

function new_blueprint_module:init()
  self._events = nil
  self:init_data()
  self:add_event()
end

function new_blueprint_module:close()
  self:remove_event()
  self:clear_data()
end

function new_blueprint_module:clear_on_disconnect()
  self:clear_data()
end

function new_blueprint_module:add_event()
  new_blueprint_module:remove_event()
  self._events = {}
  self._events[EventID.WorldEdit.LuaUI.NewBlueprintUnlockedChanged] = pack(self, new_blueprint_module._on_official_unlocked_changed)
  self._events[EventID.WorldEdit.LuaUI.SharedBlueprintImported] = pack(self, new_blueprint_module._on_shared_blueprint_imported)
  self._events[EventID.WorldEdit.LuaUI.CopyBlueprintResult] = pack(self, new_blueprint_module._on_copy_blueprint_result)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
  self._lua_events = {}
  self._lua_events[lua_event_module.event_type.on_little_corner_post_created] = pack(self, new_blueprint_module._on_xhs_post_created)
  for event_type, fun in pairs(self._lua_events) do
    lua_event_module:add_listener(event_type, fun)
  end
end

function new_blueprint_module:remove_event()
  if self._events ~= nil then
    for event_id, fun in pairs(self._events) do
      EventCenter.LuaRemoveListener(event_id, fun)
    end
    self._events = nil
  end
  if self._lua_events ~= nil then
    for event_type, fun in pairs(self._lua_events) do
      lua_event_module:remove_listener(event_type, fun)
    end
    self._lua_events = nil
  end
end

function new_blueprint_module:_on_official_unlocked_changed(arg)
  if CsNewBlueprintModuleUtil.IsNull() then
    return
  end
  local newly = CsNewBlueprintModuleUtil.GetNewlyUnlockedOfficialIds()
  local count = newly and newly.Count or 0
  for i = 0, count - 1 do
    self:_show_discover_hud(newly[i])
  end
end

function new_blueprint_module:_show_discover_hud(blueprint_id)
  local cfg = self:get_official_cfg(blueprint_id)
  local icon = cfg and cfg.icon or nil
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.blueprint_habitat_discover, {
    is_habitat = false,
    id = blueprint_id,
    icon = icon
  })
end

return new_blueprint_module
