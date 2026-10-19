spring_festival_notice_module = spring_festival_notice_module or {}
spring_festival_notice_module._cname = "spring_festival_notice_module"
require("UI/MainActivity_y1/SpringFestival/Module/SpringFestivalGateData")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/SpringFestivalNotice/Module/SpringFestivalNoticeData")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/SpringFestivalNotice/Module/SpringFestivalNoticeMain")

function spring_festival_notice_module:init()
  self:_init_data()
end

function spring_festival_notice_module:close()
end

return spring_festival_notice_module
