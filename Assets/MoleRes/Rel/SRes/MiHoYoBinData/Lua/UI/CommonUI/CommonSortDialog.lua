local M = G.Class("CommonSortDialog", G.UIWindow)
local base = G.UIWindow
local sort_item_cls = "UI/CommonUI/CommonSortItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonSortDialog"
  self.config.type = EUIType.Dialog
  self._options = {}
  self._items = {}
  self._selected_index = 1
  self._on_selected = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close_area)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self:refresh_data(data)
  self:_align_to_target(data and data.align_target, data and data.offset, data and data.pos_state)
  self:refresh_ui()
end

function M:_align_to_target(align_target, offset, pos_state)
  if is_null(align_target) then
    return
  end
  local state = pos_state or 0
  self._state_group_pos:SetState(state)
  local ratio_y = state <= 2 and 1 or 0
  local pos = CsUIUtil.CalculateCanvasLocalPosition(align_target, UIManagerInstance.canvas_rect, 0.5, ratio_y)
  local pos_x, pos_y = pos.x, pos.y
  if not_null(offset) then
    pos_x = pos_x + offset.x
    pos_y = pos_y + offset.y
  end
  self._trans_list.anchoredPosition = CS.UnityEngine.Vector2(pos_x, pos_y)
end

function M:on_destroy()
  self._options = {}
  self._items = {}
  self._on_selected = nil
  base.on_destroy(self)
end

function M:refresh_data(data)
  self._options = data and data.options or {}
  self._selected_index = data and data.selected_index or 1
  self._on_selected = data and data.on_selected or nil
end

function M:refresh_ui()
  self:_ensure_items(#self._options)
  for i = 1, #self._items do
    local function on_click()
      self:_on_item_selected(i)
    end
    
    self._items[i]:render(self._options[i], i == self._selected_index, on_click)
  end
end

function M:_ensure_items(count)
  for i = #self._items + 1, count do
    local trans = self._list_item_binder_sort:AddItem(0, true)
    self._items[i] = self:add_panel(sort_item_cls, trans)
  end
end

function M:_on_item_selected(index)
  local option = self._options[index]
  if option == nil then
    return
  end
  if self._on_selected ~= nil then
    self._on_selected(option.value, index)
  end
  self:close_self()
end

return M
