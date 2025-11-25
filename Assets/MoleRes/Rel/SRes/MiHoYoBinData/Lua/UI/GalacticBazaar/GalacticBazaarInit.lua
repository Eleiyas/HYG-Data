galactic_bazaar_module = galactic_bazaar_module or {}
galactic_bazaar_module._cname = "galactic_bazaar_module"
lua_module_mgr:require("UI/GalacticBazaar/GalacticBazaarMain")
lua_module_mgr:require("UI/GalacticBazaar/GalacticBazaarData")

function galactic_bazaar_module:init()
  self.matching_person_list = {}
  self.activity_id = 1
  self.music_id = 0
  self.dancing_action = nil
  self.dance_score_level_tbl = {}
  self._match_state = false
  self._match_state_to_open_tool = false
end

function galactic_bazaar_module:close()
end

function galactic_bazaar_module:clear_on_disconnect()
end

function galactic_bazaar_module:on_level_destroy()
  galactic_bazaar_module:set_match_state_to_open_tool(false)
end

return galactic_bazaar_module
