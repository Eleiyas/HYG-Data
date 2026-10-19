family_comment_module = family_comment_module or {}
family_comment_module._cname = "family_comment_module"
lua_module_mgr:require("UI/FamilyComment/FamilyCommentData")
lua_module_mgr:require("UI/FamilyComment/FamilyCommentCfg")
lua_module_mgr:require("UI/FamilyComment/FamilyCommentMain")
lua_module_mgr:require("UI/FamilyComment/FamilyCommentUI")

function family_comment_module:init()
  self:_init_cfg_data()
  self:_init_data()
  self:add_event()
end

function family_comment_module:close()
  self:remove_event()
end

function family_comment_module:clear_on_disconnect()
  self:_init_data()
end

return family_comment_module
