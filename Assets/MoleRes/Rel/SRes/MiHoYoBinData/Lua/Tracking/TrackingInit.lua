tracking_module = tracking_module or {}
tracking_module._cname = "tracking_module"
lua_module_mgr:require("Tracking/TrackingUI")
lua_module_mgr:require("Tracking/TrackingCommon")
lua_module_mgr:require("Tracking/TrackingMain")

function tracking_module:init()
end

function tracking_module:close()
end

function tracking_module:clear_on_disconnect()
end

return tracking_module
