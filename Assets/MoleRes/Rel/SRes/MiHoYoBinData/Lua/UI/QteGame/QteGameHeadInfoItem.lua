local M = G.Class("QteGameHeadInfoItem", G.UIBase)
local base = G.UIBase
local ShowState = {
  Empty = 0,
  Npc = 1,
  Player = 2,
  Current = 3
}

function M:on_create()
  base.on_create(self)
end

function M:set_result(is_finished, is_player_win, npc_id, is_current, play_result_anim)
  local state = ShowState.Empty
  if is_finished then
    state = is_player_win and ShowState.Player or ShowState.Npc
  elseif is_current then
    state = ShowState.Current
  end
  self._state_group_show:SetState(state)
  if not is_finished then
    return
  end
  if play_result_anim then
    self._animator:SetTrigger(is_player_win and "player" or "npc")
  end
  if is_player_win then
    player_module:set_player_icon(self._img_player_icon, self:get_load_proxy(), false)
    return
  end
  if npc_id == nil or npc_id == 0 then
    return
  end
  npc_module:set_npc_icon_by_id(self._img_npc_icon, npc_id, self:get_load_proxy(), false)
end

return M
