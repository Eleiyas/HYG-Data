collection_module = collection_module or {}
collection_module._cname = "collection_module"
lua_module_mgr:require("UI/Collection/CollectionCommon")
lua_module_mgr:require("UI/Collection/CollectionUI")
lua_module_mgr:require("UI/Collection/CollectionCfg")
lua_module_mgr:require("UI/Collection/CollectionData")
lua_module_mgr:require("UI/Collection/CollectionMain")

function collection_module:init()
  collection_module:_init_cfg()
  collection_module:_init_data()
end

function collection_module:close()
end

function collection_module:clear_on_disconnect()
  collection_module:_init_data()
end

return collection_module
