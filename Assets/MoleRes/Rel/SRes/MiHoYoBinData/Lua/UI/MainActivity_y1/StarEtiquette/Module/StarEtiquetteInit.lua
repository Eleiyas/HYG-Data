star_etiquette_module = star_etiquette_module or {}
star_etiquette_module._cname = "star_etiquette_module"
lua_module_mgr:require("UI/MainActivity_y1/StarEtiquette/Module/StarEtiquetteMain")

function star_etiquette_module:init()
  self._is_opening_sign_up_page = false
  self:register_tracking_navigation()
end

function star_etiquette_module:close()
  self._is_opening_sign_up_page = false
  self:unregister_tracking_navigation()
end

function star_etiquette_module:clear_on_disconnect()
  self._is_opening_sign_up_page = false
end

return star_etiquette_module
