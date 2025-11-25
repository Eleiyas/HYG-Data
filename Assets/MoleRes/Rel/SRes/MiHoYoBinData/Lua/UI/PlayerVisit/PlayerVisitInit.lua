player_visit_module = player_visit_module or {}
player_visit_module._cname = "player_visit_module"
lua_module_mgr:require("UI/PlayerVisit/PlayerVisitMain")
lua_module_mgr:require("UI/PlayerVisit/PlayerVisitData")

function player_visit_module:init()
  self._events = nil
  player_visit_module:add_event()
  self.player_visit_page = nil
  self.main_island_permission = nil
  self.permission_info = {}
  self.record_infos = {}
  self.cur_permission_id = {
    [1] = 0,
    [2] = 0,
    [3] = 0
  }
  player_visit_module:get_player_visit_permission_info()
end

function player_visit_module:close()
  player_visit_module:remove_event()
end

function player_visit_module:clear_on_disconnect()
end

return player_visit_module
