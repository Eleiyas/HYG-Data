report_module = report_module or {}
report_module._cname = "report_module"
lua_module_mgr:require("UI/Report/Module/ReportCfg")
lua_module_mgr:require("UI/Report/Module/ReportMain")
lua_module_mgr:require("UI/Report/Module/ReportCommon")

function report_module:init()
end

function report_module:close()
end

function report_module:clear_on_disconnect()
end

return report_module
