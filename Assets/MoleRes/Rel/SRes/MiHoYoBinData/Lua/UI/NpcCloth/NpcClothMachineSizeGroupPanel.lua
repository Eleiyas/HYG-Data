local M = G.Class("NpcClothMachineSizeGroupPanel", G.UIPanel)
local base = G.UIPanel
local SIZE_SHAPE_ITEM_CLS = "UI/NpcCloth/NpcClothMachineSizeShapeItem"

function M:init()
  base.init(self)
  self._callbacks = {}
  self._view_context = {}
  self._size_shape_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_ensure_switch_button()
end

function M:refresh(data, callbacks)
  self._callbacks = callbacks or self._callbacks or {}
  self._view_context = data and data.view_context or self._view_context or {}
  self:_refresh_size_shape_items()
end

function M:_refresh_size_shape_items()
  if is_null(self._obj_size_shape_template) then
    return
  end
  UIUtil.set_active(self._obj_size_shape_template, false)
  local mount_points = self:_get_size_shape_mount_points()
  local latest_goods = self._view_context.latest_selected_goods
  for index, shape in ipairs(self:_get_shape_list()) do
    local item = self:_get_or_create_size_shape_item(index, mount_points[index])
    if item then
      local npc_id = self:_get_selected_npc_by_shape(shape)
      local disabled = self:_is_latest_goods_unwearable_for_shape(latest_goods, npc_id, shape)
      item:refresh({
        shape = shape,
        npc_id = npc_id,
        disabled = disabled
      }, {
        current_shape = self._view_context.mannequin_shape,
        on_click_shape = pack(self, M._on_click_shape)
      })
    end
  end
end

function M:_is_latest_goods_unwearable_for_shape(latest_goods, npc_id, shape)
  if is_null(latest_goods) or (npc_id or 0) <= 0 then
    return false
  end
  return not npc_cloth_module.is_item_wearable_by_npc(latest_goods, npc_id, shape)
end

function M:_get_or_create_size_shape_item(index, parent)
  if self._size_shape_items[index] then
    return self._size_shape_items[index]
  end
  if is_null(parent) or is_null(self._obj_size_shape_template) then
    return nil
  end
  local template_trans = self._obj_size_shape_template.transform or self._obj_size_shape_template
  local trans = parent:AddChildFromPrefab(template_trans)
  local item = self:add_panel(SIZE_SHAPE_ITEM_CLS, trans)
  self._size_shape_items[index] = item
  return item
end

function M:_get_size_shape_mount_points()
  return {
    self._trans_size_shape_pos_s,
    self._trans_size_shape_pos_m,
    self._trans_size_shape_pos_l
  }
end

function M:_get_shape_list()
  return self._view_context.shape_list or npc_cloth_module.get_default_shape_list()
end

function M:_get_selected_npc_by_shape(shape)
  local selected_map = self._view_context.selected_npc_by_shape or {}
  return selected_map[shape] or 0
end

function M:_ensure_switch_button()
  if is_null(self._btn_switch_npc) then
    return
  end
  self:bind_callback(self._btn_switch_npc, pack(self, M._on_switch_npc_click))
end

function M:_on_click_shape(shape, npc_id, data)
  if self._callbacks and self._callbacks.on_click_shape then
    self._callbacks.on_click_shape(shape, npc_id, data)
  end
end

function M:_on_switch_npc_click()
  shop_module:open_npc_cloth_choose_npc_dialog({
    npc_list = self._view_context.npc_list or {},
    selected_npc_by_shape = self:_get_selected_npc_by_shape_map(),
    confirm_callback = pack(self, M._on_choose_npc_confirm)
  })
end

function M:_on_choose_npc_confirm(selected_npc_by_shape)
  self._view_context.selected_npc_by_shape = self:_normalize_selected_npc_by_shape(selected_npc_by_shape or {})
  self:_refresh_size_shape_items()
  if self._callbacks and self._callbacks.on_choose_npc_confirm then
    self._callbacks.on_choose_npc_confirm(self._view_context.selected_npc_by_shape)
  end
end

function M:_get_selected_npc_by_shape_map()
  local result = {}
  for shape, npc_id in pairs(self._view_context.selected_npc_by_shape or {}) do
    result[tonumber(shape) or shape] = npc_id
  end
  return result
end

function M:_normalize_selected_npc_by_shape(source)
  return npc_cloth_module.normalize_selected_npc_by_shape(source)
end

return M
