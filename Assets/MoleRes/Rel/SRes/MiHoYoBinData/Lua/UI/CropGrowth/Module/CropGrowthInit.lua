crop_growth_module = crop_growth_module or {}
crop_growth_module._cname = "crop_growth_module"
lua_module_mgr:require("UI/CropGrowth/Module/CropGrowthCommon")
lua_module_mgr:require("UI/CropGrowth/Module/CropGrowthData")
lua_module_mgr:require("UI/CropGrowth/Module/CropGrowthMain")

function crop_growth_module:init()
  crop_growth_module:add_event()
end

function crop_growth_module:close()
  crop_growth_module:remove_event()
end

function crop_growth_module:clear_on_disconnect()
end

return crop_growth_module
