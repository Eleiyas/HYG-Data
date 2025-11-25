back_bag_module = back_bag_module or {}
back_bag_module._cname = "back_bag_module"
lua_module_mgr:require("BackBag/BackBagCommon")
lua_module_mgr:require("BackBag/BackBagUI")
lua_module_mgr:require("BackBag/BackBagCfg")
lua_module_mgr:require("BackBag/BackBagData")
lua_module_mgr:require("BackBag/BackBagMain")
lua_module_mgr:require("BackBag/BackBagNet")

function back_bag_module:init()
  self._events = nil
  self:_init_data()
  self._check_temporary_bag_fun = nil
  back_bag_module:add_event()
  self:_init_cfg()
  self._tbl_all_back_pack_filter_cfgs = nil
end

function back_bag_module:close()
  back_bag_module:remove_event()
end

return back_bag_module
