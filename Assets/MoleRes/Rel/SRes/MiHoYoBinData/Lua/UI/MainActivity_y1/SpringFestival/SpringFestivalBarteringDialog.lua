local bartering_item_cls = "UI/MainActivity_y1/SpringFestival/SpringFestivalBarteringItem"
local M = G.Class("SpringFestivalBarteringDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_BarteringDialog"
  self.config.type = EUIType.Dialog
  self.config.input_penetrate = true
  self.config.order_in_layer = 1
  self._npc_id = 0
  self._npc_exchangeable_items = nil
  self._npc_exchangeable_item_counts = nil
  self._player_exchangeable_items = nil
  self._player_exchangeable_item_counts = nil
  self._npc_item_pool = {}
  self._player_item_pool = {}
  self._list_item_binder_layout_npc_list = nil
  self._list_item_binder_layout_my_list = nil
  self._obj_skip_arrow = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  local data = self:get_extra_data()
  self._npc_id = data.npc_id
  self._npc_exchangeable_items = data.npc_exchangeable_items
  self._npc_exchangeable_item_counts = data.npc_exchangeable_item_counts
  self._player_exchangeable_items = data.player_exchangeable_items
  self._player_exchangeable_item_counts = data.player_exchangeable_item_counts
  self:_refresh_ui()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  EventCenter.Broadcast(EventID.LuaSpringFestivalBarteringUserClose)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_ui()
  local has_npc_items = self._npc_exchangeable_items and #self._npc_exchangeable_items > 0
  local has_player_items = self._player_exchangeable_items and 0 < #self._player_exchangeable_items
  if not is_null(self._obj_skip_arrow) then
    UIUtil.set_active(self._obj_skip_arrow, has_npc_items and has_player_items)
  end
  self:_refresh_list(self._list_item_binder_layout_npc_list, self._npc_item_pool, self._npc_exchangeable_items, self._npc_exchangeable_item_counts, self._npc_id)
  self:_refresh_list(self._list_item_binder_layout_my_list, self._player_item_pool, self._player_exchangeable_items, self._player_exchangeable_item_counts, 0)
end

function M:_refresh_list(list_binder, pool, item_ids, item_counts, npc_id)
  if is_null(list_binder) then
    return
  end
  if item_ids == nil then
    return
  end
  local count = #item_ids
  for i = 1, count do
    local item = pool[i]
    if item == nil then
      local obj = list_binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(bartering_item_cls, obj)
        pool[i] = item
        UIUtil.set_active(obj, true)
      end
    end
    if item then
      local item_id = item_ids[i]
      local item_count = item_counts and item_counts[i] or 0
      local is_last = i == count
      item:set_data(item_id, item_count, npc_id, is_last)
    end
  end
  for i = count + 1, #pool do
    if pool[i] then
      UIUtil.set_active(pool[i].game_obj, false)
    end
  end
end

return M
