local M = G.Class("CurioEmporiumTopUpPanel", G.CurioEmporiumEntrancePanelBase)
local base = G.CurioEmporiumEntrancePanelBase
local top_up_item_cls = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumTopUpItem"
local QUERY_TIMEOUT = 15
local MAX_ITEM_COUNT = 6

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumTopUpPanel"
end

function M:on_create()
  self._items = {}
  self._item_objs = nil
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  if self._query_timer then
    self._query_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOnStoreGoodsInfoRefreshed, pack(self, M._on_store_goods_info_refreshed))
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:_on_store_goods_info_refreshed(config_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if self._query_timer then
    return
  end
  local matched = false
  for _, cfg in ipairs(self._cfg_list or {}) do
    if curio_emporium_module:is_refreshed_goods_match(cfg, config_id) then
      matched = true
      break
    end
  end
  if not matched then
    return
  end
  self:_refresh_items()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._query_timer then
    return
  end
  self._query_timer = self._query_timer + deltaTime
  if self._query_timer >= QUERY_TIMEOUT then
    self:_on_query_finish(false, nil)
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
end

function M:refresh()
  local cfgs = curio_emporium_module:get_all_top_up_cfg()
  if not cfgs then
    return
  end
  self._cfg_list = {}
  for _, cfg in pairs(cfgs) do
    table.insert(self._cfg_list, cfg)
  end
  table.sort(self._cfg_list, function(a, b)
    return a.id < b.id
  end)
  self._display_cfg_list = nil
  UIUtil.set_active(self._obj_root, false)
  self:_hide_all_items()
  self._query_timer = 0
  EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
  curio_emporium_module:query_virtual_currency_goods(pack(self, M._on_query_finish))
end

function M:_on_query_finish(success, goods_dict)
  if not self._query_timer then
    return
  end
  self._query_timer = nil
  EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  if is_null(self.game_obj) then
    return
  end
  self._goods_dict = success and goods_dict or nil
  self._display_cfg_list = self:_filter_displayable_cfgs()
  UIUtil.set_active(self._obj_root, #self._display_cfg_list > 0)
  self:_refresh_items()
end

function M:_filter_displayable_cfgs()
  local result = {}
  for _, cfg in ipairs(self._cfg_list or {}) do
    if curio_emporium_module:is_goods_displayable(cfg, self._goods_dict) then
      table.insert(result, cfg)
    end
  end
  return result
end

function M:_collect_item_objs()
  if self._item_objs then
    return
  end
  self._item_objs = {
    self._obj_top_up_item_1,
    self._obj_top_up_item_2,
    self._obj_top_up_item_3,
    self._obj_top_up_item_4,
    self._obj_top_up_item_5,
    self._obj_top_up_item_6
  }
end

function M:_hide_all_items()
  self:_collect_item_objs()
  for i = 1, MAX_ITEM_COUNT do
    local obj = self._item_objs[i]
    if not is_null(obj) then
      UIUtil.set_active(obj, false)
    end
  end
end

function M:_get_goods_data(cfg)
  return curio_emporium_module:get_sdk_goods_data(cfg, self._goods_dict)
end

function M:_refresh_items()
  self:_collect_item_objs()
  local cfg_list = self._display_cfg_list or {}
  local show_count = math.min(#cfg_list, MAX_ITEM_COUNT)
  for i = 1, MAX_ITEM_COUNT do
    local obj = self._item_objs[i]
    if not is_null(obj) then
      if i <= show_count then
        local item = self._items[i]
        if not item then
          item = self:add_panel(top_up_item_cls, obj)
          self._items[i] = item
        end
        UIUtil.set_active(item.game_obj, true)
        item:refresh(cfg_list[i], self:_get_goods_data(cfg_list[i]))
      else
        UIUtil.set_active(obj, false)
      end
    end
  end
end

return M
