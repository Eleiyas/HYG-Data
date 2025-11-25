star_friend_social_module = star_friend_social_module or {}
star_friend_social_module._cname = "star_friend_social_module"
lua_module_mgr:require("UI/Friend/StarFriendSocialMain")
lua_module_mgr:require("UI/Friend/StarFriendSocialData")

function star_friend_social_module:init()
  self._info_scene_obj = nil
  self._handles = {}
  self._available_friend_count = 6
  self._info_star_obj_tbl = {}
  self._player_entity_guid_tbl = {}
  self._player_entity_guid = nil
  self.is_far = true
  self._is_enter = true
  self.cur_friend_uid = -1
  self._info_star_obj_tbl = {}
  self.player_titles = {}
end

function star_friend_social_module:close()
end

function star_friend_social_module:clear_on_disconnect()
end

return star_friend_social_module
