world_editor_module = world_editor_module or {}
world_editor_module._cname = "world_editor_module"
lua_module_mgr:require("UI/WorldEditor/WorldEditorUI")
lua_module_mgr:require("UI/WorldEditor/WorldEditorCommon")

function world_editor_module:init()
end

function world_editor_module:close()
end

return world_editor_module
