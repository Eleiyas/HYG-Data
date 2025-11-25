social_module = social_module or {}
social_module._cname = "social_module"
lua_module_mgr:require("Social/SocialNet")
lua_module_mgr:require("Social/SocialData")
lua_module_mgr:require("Social/SocialMain")

function social_module:init()
  social_module:_init_data()
  social_module:register_cmd_handler()
  social_module:add_event()
end

social_module.social_multi_play_visite_interact_type = {
  apply = 0,
  invite = 1,
  through = 2,
  first_query = 3
}

function social_module:close()
  social_module:un_register_cmd_handler()
  social_module:remove_event()
end

function social_module:clear_on_disconnect()
  social_module:_init_data()
end

return social_module or {}
