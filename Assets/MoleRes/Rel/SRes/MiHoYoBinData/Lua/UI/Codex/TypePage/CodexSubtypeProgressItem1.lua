local M = G.Class("CodexSubtypeProgressItem1", "UI/Codex/TypePage/CodexSubtypeProgressItemBase")
local base = G.CodexSubtypeProgressItemBase
local MOBILE_NODE_SPACING = 200
local MOBILE_NODE_START_OFFSET = 110
local DEFAULT_NODE_SPACING = 200
local DEFAULT_NODE_START_OFFSET = 178

local function get_node_layout()
  local runtime_platform = ApplicationUtil.GetTargetPlatform()
  if runtime_platform == CS.Proto.PlatformType.Android or runtime_platform == CS.Proto.PlatformType.Ios then
    return MOBILE_NODE_SPACING, MOBILE_NODE_START_OFFSET
  end
  return DEFAULT_NODE_SPACING, DEFAULT_NODE_START_OFFSET
end

function M:on_create()
  base.on_create(self)
  if self._progress_bar_panel then
    local node_spacing, node_start_offset = get_node_layout()
    self._progress_bar_panel:set_equal_spacing(node_spacing, node_start_offset)
    self._progress_bar_panel:set_show_reward_icon(true)
    self._progress_bar_panel:set_skip_bg(true)
  end
end

function M:_refresh_outer_icon()
  if is_null(self._trans_icon) then
    return
  end
end

return M
