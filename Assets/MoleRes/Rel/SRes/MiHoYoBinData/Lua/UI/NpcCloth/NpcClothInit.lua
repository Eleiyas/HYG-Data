npc_cloth_module = npc_cloth_module or {}
npc_cloth_module._cname = "npc_cloth_module"
lua_module_mgr:require("UI/NpcCloth/NpcClothModule")

function npc_cloth_module:init()
  self:clear_data()
  self:clear_helper_cache()
end

function npc_cloth_module:close()
  self:clear_data()
  self:clear_helper_cache()
end

function npc_cloth_module:clear_on_disconnect()
  self:clear_data()
  self:clear_helper_cache()
end

return npc_cloth_module
