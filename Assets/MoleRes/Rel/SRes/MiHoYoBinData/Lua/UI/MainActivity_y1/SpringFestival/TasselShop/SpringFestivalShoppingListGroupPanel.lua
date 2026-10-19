local M = G.Class("SpringFestivalShoppingListGroupPanel", G.UIPanel)
local base = G.UIPanel
local card_cls = "UI/MainActivity_y1/SpringFestival/TasselShop/SpringFestivalShoppingCardItem"

function M:init()
  base.init(self)
  self._items = {}
  self._on_select_goods = nil
  self._columns_cache = nil
end

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_select_goods = data.on_select_goods
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  data = data or {}
  self._on_select_goods = data.on_select_goods
end

function M:_create_item(index)
  local item_obj
  if self._item_group ~= nil and self._item_group.AddItem ~= nil then
    item_obj = self._item_group:AddItem(0)
  end
  if item_obj == nil then
    Logger.LogWarning(string.format("[SpringFestivalShoppingListGroupPanel] AddItem failed, index=%d", index))
    return nil
  end
  local item = self:add_panel(card_cls, item_obj, {
    on_select_goods = pack(self, M._on_item_selected)
  })
  self._items[index] = item
  return item
end

function M:_on_item_selected(goods, card_item)
  if self._on_select_goods ~= nil then
    self._on_select_goods(goods, card_item)
  end
end

function M:refresh(goods_list, selected_goods_id)
  goods_list = goods_list or {}
  selected_goods_id = selected_goods_id or 0
  Logger.Log(string.format("[SpringFestivalShoppingListGroupPanel] refresh goods_count=%d", #goods_list))
  local cols = self:_get_columns_per_row()
  local remainder = 0 < cols and #goods_list % cols or 0
  local total_slots = remainder == 0 and #goods_list or #goods_list + cols - remainder
  for i = 1, total_slots do
    local goods = goods_list[i]
    local item = self._items[i]
    if item == nil then
      item = self:_create_item(i)
    end
    if item ~= nil then
      item:set_active(true)
      if goods ~= nil then
        item:refresh(goods, (goods.goods_id or 0) == selected_goods_id)
      else
        item:set_empty(1)
      end
    end
  end
  for i = total_slots + 1, #self._items do
    if self._items[i] ~= nil then
      self._items[i]:set_active(false)
    end
  end
end

function M:_get_columns_per_row()
  if self._columns_cache ~= nil and self._columns_cache > 0 then
    return self._columns_cache
  end
  local root_trans
  if self._item_group ~= nil then
    root_trans = self._item_group.transform
  end
  if root_trans ~= nil then
    local grid = root_trans:GetComponent(typeof(CS.UnityEngine.UI.GridLayoutGroup))
    local rect_trans = root_trans:GetComponent(typeof(CS.UnityEngine.RectTransform))
    if not_null(grid) then
      if grid.constraint == CS.UnityEngine.UI.GridLayoutGroup.Constraint.FixedColumnCount then
        self._columns_cache = grid.constraintCount
        return self._columns_cache
      end
      local container_width = 0
      if not_null(rect_trans) then
        container_width = rect_trans.rect.width - grid.padding.left - grid.padding.right
      end
      local cell_width = grid.cellSize.x + grid.spacing.x
      if 0 < cell_width and 0 < container_width then
        local cols = math.floor((container_width + grid.spacing.x) / cell_width)
        if 0 < cols then
          self._columns_cache = cols
          return self._columns_cache
        end
      end
    end
  end
  return 3
end

function M:refresh_selected(selected_goods_id)
  selected_goods_id = selected_goods_id or 0
  for _, item in ipairs(self._items) do
    if item ~= nil and item.is_active then
      local goods_id = item:get_goods_id() or 0
      local is_selected = 0 < goods_id and goods_id == selected_goods_id
      item:set_selected(is_selected)
    end
  end
end

function M:refresh_tracking_point_state()
  for _, item in ipairs(self._items) do
    if item ~= nil and item.is_active and item.refresh_tracking_point_state ~= nil then
      item:refresh_tracking_point_state()
    end
  end
end

return M
