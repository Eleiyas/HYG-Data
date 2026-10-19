local M = G.Class("CurioEmporiumEntranceHotSaleGroup", G.UIPanel)
local base = G.UIPanel
local item_cls = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceHotSaleItem"

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
  self._item_pool = {}
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
end

function M:refresh(tag, cfgs, goods_dict, on_item_selected)
  self._tag = tag
  self._cfgs = cfgs
  self._goods_dict = goods_dict
  self._on_item_selected = on_item_selected
  self:_refresh_title()
  self:_refresh_items()
end

function M:_refresh_title()
  local tag_name = curio_emporium_module:get_gift_group_name(self._tag)
  if tag_name then
    UIUtil.set_text(self._txt_title, tag_name)
  end
end

function M:_get_columns_per_row()
  if self._cols_cache and self._cols_cache > 0 then
    return self._cols_cache
  end
  local grid = self._grid_layout
  if is_null(grid) then
    return 0
  end
  if is_null(self._trans_items) then
    return 0
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_items)
  local container_width = self._trans_items.rect.width - grid.padding.left - grid.padding.right
  local cell_width = grid.cellSize.x + grid.spacing.x
  if 0 < cell_width and 0 < container_width then
    local cols = math.floor((container_width + grid.spacing.x) / cell_width)
    if 0 < cols then
      self._cols_cache = cols
      return cols
    end
  end
  return 0
end

function M:_refresh_items()
  local count = #self._cfgs
  local cols = self:_get_columns_per_row()
  local total_slots = count
  if 0 < count and 0 < cols then
    total_slots = math.ceil(count / cols) * cols
  end
  for i = 1, total_slots do
    local item = self._item_pool[i]
    if not item then
      local obj = self._list_item_binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(item_cls, obj)
        self._item_pool[i] = item
      end
    end
    if item then
      if i <= count then
        local cfg = self._cfgs[i]
        local goods_data
        if cfg and not cfg:goodsid_is_empty() then
          if self._goods_dict then
            local ok, data = self._goods_dict:TryGetValue(cfg.goodsid)
            if ok then
              goods_data = data
            end
          end
        elseif cfg then
          goods_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
        end
        item:refresh(cfg, goods_data, self._on_item_selected, self:get_load_proxy())
      else
        item:set_empty()
      end
      UIUtil.set_active(item.game_obj, true)
    end
  end
  for i = total_slots + 1, #self._item_pool do
    local item = self._item_pool[i]
    if item then
      UIUtil.set_active(item.game_obj, false)
    end
  end
end

return M
