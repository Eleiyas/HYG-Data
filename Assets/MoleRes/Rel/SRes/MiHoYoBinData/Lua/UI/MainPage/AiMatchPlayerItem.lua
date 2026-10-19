local M = G.Class("AiMatchPlayerItem", G.UIBase)
local base = G.UIBase
local ITEM_STATE_HOST_QUEUING = 0
local ITEM_STATE_HOST_SUCCESS = 1
local ITEM_STATE_EMPTY = 2
local ITEM_STATE_GUEST_QUEUING = 3
local ITEM_STATE_GUEST_SUCCESS = 4

function M:on_create()
  base.on_create(self)
end

function M:set_host(pos, is_ready, show_ahead_count)
  if not is_null(self._state_group) then
    self._state_group:SetState(is_ready and ITEM_STATE_HOST_SUCCESS or ITEM_STATE_HOST_QUEUING)
  end
  if not is_null(self._txt_wait_time) then
    if show_ahead_count then
      local ahead = math.max((tonumber(pos) or 1) - 1, 1)
      UIUtil.set_text(self._txt_wait_time, UIUtil.get_text_by_id("AiQueue_AheadPlayerCount", ahead))
    else
      UIUtil.set_text(self._txt_wait_time, "")
    end
  end
  if not is_null(self._txt_player_name) then
    UIUtil.set_text(self._txt_player_name, player_module:get_player_name())
  end
  if not is_null(self._img_head) then
    player_module:set_player_icon(self._img_head, self:get_load_proxy(), false)
  end
end

function M:set_guest_queuing()
  if not is_null(self._state_group) then
    self._state_group:SetState(ITEM_STATE_GUEST_QUEUING)
  end
end

function M:set_guest_matched(player_data)
  if not is_null(self._state_group) then
    self._state_group:SetState(ITEM_STATE_GUEST_SUCCESS)
  end
  if player_data then
    if not is_null(self._txt_player_name) and player_data.PlayerName then
      UIUtil.set_text(self._txt_player_name, player_data.PlayerName)
    end
    if not is_null(self._img_head) and player_data.AvatarId then
      local head_cfg = LocalDataUtil.get_value(typeof(BPlayerHeadCfg), player_data.AvatarId)
      if head_cfg then
        UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
      end
    end
  end
end

function M:set_empty()
  if not is_null(self._state_group) then
    self._state_group:SetState(ITEM_STATE_EMPTY)
  end
  if not is_null(self._txt_player_name) then
    UIUtil.set_text(self._txt_player_name, "")
  end
end

return M
