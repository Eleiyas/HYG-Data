local M = G.Class("LiteCommonBagPanel", "UI/PacketView/CommonBagPanel")
local base = G.CommonBagPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteCommonBagPanel"
end

function M:on_create()
  base.on_create(self)
end

function M:refresh_ui(tog_sort_type)
  base.refresh_ui(self, tog_sort_type)
  self:_refresh_tab_sidebar_state()
end

function M:_refresh_tab_sidebar_state()
  if is_null(self._state_group_tab) then
    return
  end
  local visible_tab_count = 0
  for i = 1, #(self._all_tab_infos or {}) do
    local info = self._all_tab_infos[i]
    if info and info.IsShow and not info.isHideInUI then
      visible_tab_count = visible_tab_count + 1
    end
  end
  self._state_group_tab:SetState(visible_tab_count <= 1 and 1 or 0)
end

function M:_refresh_filter_state()
  if is_null(self._ui_state_group_filter) then
    return
  end
  local tab_info = self:get_cur_tab_info()
  local show_filter = self:init_sort_info() and tab_info and not tab_info.isHideFilterUI
  self._ui_state_group_filter:SetState(show_filter and 1 or 0)
end

return M
