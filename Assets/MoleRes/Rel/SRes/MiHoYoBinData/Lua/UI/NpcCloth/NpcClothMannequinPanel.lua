local M = G.Class("NpcClothMannequinPanel", G.UIPanel)
local base = G.UIPanel
local SelectionModel = require("UI/NpcCloth/NpcClothMachineSelectionModel")

function M:init()
  base.init(self)
  self._selection_model = SelectionModel.new()
  self._mannequin_npc_id = 0
  self._scene_npc_root = nil
  self._trans_drag_area = nil
  self._has_bound_drag_area = false
  self._is_drag_pressing = false
  self._base_preset_by_slot = {}
  self._is_preset_edit_mode = false
  self._current_wearable_item_id_map = {}
end

function M:on_create()
  base.on_create(self)
  self:_bind_drag_area()
end

function M:on_destroy()
  CsShopModuleUtil.DestroyNpcClothShopMannequin()
  base.on_destroy(self)
end

function M:set_scene_npc_root(npc_root)
  self._scene_npc_root = npc_root
end

function M:set_mannequin(npc_id, context)
  self._mannequin_npc_id = npc_id or 0
  self:_refresh_mannequin_entity()
  local snapshot = self:revalidate_selection(context)
  self:_refresh_preview_wearables()
  return snapshot
end

function M:set_base_preset(preset_map)
  self._base_preset_by_slot = self:_copy_preset_map(preset_map)
  if self._is_preset_edit_mode ~= true then
    self:_refresh_preview_wearables()
  end
end

function M:enter_preset_edit_mode()
  self._is_preset_edit_mode = true
  self:_refresh_preview_wearables()
end

function M:exit_preset_edit_mode(preset_map)
  self._base_preset_by_slot = self:_copy_preset_map(preset_map)
  self._is_preset_edit_mode = false
  self:_refresh_preview_wearables()
end

function M:apply_preset_preview(preset_map)
  self._base_preset_by_slot = self:_copy_preset_map(preset_map)
  if self._is_preset_edit_mode == true then
    self:_refresh_preview_wearables_incrementally()
  end
end

function M:clear_selection()
  local snapshot = self._selection_model:clear_selection()
  self:_apply_selection_snapshot(snapshot)
  return snapshot
end

function M:toggle_goods(goods, view_state)
  local snapshot = self._selection_model:toggle_goods(goods, view_state)
  self:_apply_selection_snapshot(snapshot)
  return snapshot
end

function M:revalidate_selection(context)
  local snapshot = self._selection_model:revalidate_selection(context)
  self:_apply_selection_snapshot(snapshot)
  return snapshot
end

function M:reconcile_selection(shop_groups, context)
  local snapshot = self._selection_model:reconcile_selection(shop_groups, context)
  self:_apply_selection_snapshot(snapshot)
  return snapshot
end

function M:get_selected_goods_list()
  return self._selection_model:get_selected_goods_list()
end

function M:get_selected_total_price()
  local total = 0
  for _, goods in ipairs(self._selection_model:get_selected_goods_list() or {}) do
    total = total + (goods.Price or 0)
  end
  return total
end

function M:_bind_drag_area()
  if self._has_bound_drag_area or is_null(self._trans_drag_area) then
    return
  end
  self.binder:BindViewCallback(self._trans_drag_area, EventTriggerType.PointerDown, pack(self, M._on_drag_area_pointer_down))
  self.binder:BindViewCallback(self._trans_drag_area, EventTriggerType.PointerUp, pack(self, M._on_drag_area_pointer_up))
  self.binder:BindViewCallback(self._trans_drag_area, EventTriggerType.Drag, pack(self, M._on_drag_area_drag))
  self._has_bound_drag_area = true
end

function M:_on_drag_area_pointer_down(evt)
  self._is_drag_pressing = true
end

function M:_on_drag_area_pointer_up(evt)
  self._is_drag_pressing = false
end

function M:_on_drag_area_drag(evt)
  if not self._is_drag_pressing then
    return
  end
  local delta_x = evt and evt.delta and evt.delta.x or 0
  if delta_x == 0 then
    return
  end
  CsShopModuleUtil.NpcClothShopRotateMannequin(delta_x)
end

function M:_put_on_goods(goods)
  if is_null(goods) then
    return
  end
  local item_id = self:_get_wearable_item_id(goods)
  CsShopModuleUtil.NpcClothShopPutOnCloth(item_id, npc_cloth_module.get_outfit_try_on_anim(item_id), true)
  self._current_wearable_item_id_map[item_id] = true
end

function M:_take_off_goods(goods)
  if is_null(goods) then
    return
  end
  local item_id = self:_get_wearable_item_id(goods)
  CsShopModuleUtil.NpcClothShopTakeOffCloth(item_id, true)
  self._current_wearable_item_id_map[item_id] = nil
end

function M:_refresh_mannequin_entity()
  if self._mannequin_npc_id <= 0 then
    CsShopModuleUtil.DestroyNpcClothShopMannequin()
    return
  end
  if is_null(self._scene_npc_root) then
    Logger.LogError("[NpcClothMannequinPanel] missing scene npc root")
    return
  end
  CsShopModuleUtil.NpcClothShopSetMannequin(self._mannequin_npc_id, self._scene_npc_root)
end

function M:_refresh_preview_wearables()
  local wearables = self:_collect_preview_wearables()
  CsShopModuleUtil.NpcClothShopPutOnClothList(wearables)
  self:_rebuild_current_wearable_map(wearables)
end

function M:_refresh_preview_wearables_incrementally()
  local wearables = self:_collect_preview_wearables()
  CsShopModuleUtil.NpcClothShopSyncClothList(wearables)
  self:_rebuild_current_wearable_map(wearables)
end

function M:_collect_preview_wearables()
  local wearables = {}
  local used_slot_set = {}
  if self._is_preset_edit_mode ~= true then
    for _, goods in ipairs(self._selection_model:get_selected_goods_list() or {}) do
      local item_id = self:_get_wearable_item_id(goods)
      if 0 < item_id then
        wearables[#wearables + 1] = item_id
        for slot_id, _ in pairs(npc_cloth_module.get_outfit_slot_set(item_id)) do
          used_slot_set[slot_id] = true
        end
      end
    end
  end
  for _, item_data in pairs(self._base_preset_by_slot or {}) do
    local item_id = self:_get_wearable_item_id(item_data)
    if 0 < item_id then
      local conflict = false
      for slot_id, _ in pairs(npc_cloth_module.get_outfit_slot_set(item_id)) do
        if used_slot_set[slot_id] == true then
          conflict = true
          break
        end
      end
      if not conflict then
        wearables[#wearables + 1] = item_id
      end
    end
  end
  return wearables
end

function M:_apply_selection_snapshot(snapshot)
  if snapshot == nil then
    return
  end
  for _, goods in ipairs(snapshot.added_goods_list or {}) do
    self:_put_on_goods(goods)
  end
  for _, goods in ipairs(snapshot.removed_goods_list or {}) do
    self:_take_off_goods(goods)
  end
  if snapshot.need_refresh_preview == true or #(snapshot.removed_goods_list or {}) > 0 then
    self:_refresh_preview_wearables()
  end
end

function M:_copy_preset_map(source)
  local result = {}
  for slot_key, item_data in pairs(source or {}) do
    result[slot_key] = {}
    for key, value in pairs(item_data) do
      result[slot_key][key] = value
    end
  end
  return result
end

function M:_take_off_all_known_wearables()
  for item_id, _ in pairs(self._current_wearable_item_id_map or {}) do
    if 0 < item_id then
      CsShopModuleUtil.NpcClothShopTakeOffCloth(item_id, true)
    end
  end
  table.clear(self._current_wearable_item_id_map)
end

function M:_rebuild_current_wearable_map(wearables)
  table.clear(self._current_wearable_item_id_map)
  for _, item_id in ipairs(wearables or {}) do
    if 0 < (item_id or 0) then
      self._current_wearable_item_id_map[item_id] = true
    end
  end
end

function M:_get_wearable_item_id(goods_or_item)
  if type(goods_or_item) == "number" then
    return goods_or_item
  end
  return goods_or_item and (goods_or_item.ItemID or goods_or_item.item_id or goods_or_item.id) or 0
end

return M
