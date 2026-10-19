curio_emporium_module = curio_emporium_module or {}
curio_emporium_module._cname = "curio_emporium_module"
lua_module_mgr:require("UI/CurioEmporium/Module/CurioEmporiumData")
curio_emporium_module.entrance_tag_type = {
  first_recharge = 1,
  season_bp = 2,
  hot_sale = 3,
  top_up_mall = 4,
  monthly_pass = 5
}
curio_emporium_module.top_up_currency_id = 200019
curio_emporium_module.entrance_tag_coin_cfg = {
  [curio_emporium_module.entrance_tag_type.first_recharge] = {
    {
      coin_id = curio_emporium_module.top_up_currency_id,
      show_add = true
    }
  },
  [curio_emporium_module.entrance_tag_type.season_bp] = {
    {
      coin_id = curio_emporium_module.top_up_currency_id,
      show_add = true
    }
  },
  [curio_emporium_module.entrance_tag_type.hot_sale] = {
    {
      coin_id = curio_emporium_module.top_up_currency_id,
      show_add = true
    }
  },
  [curio_emporium_module.entrance_tag_type.top_up_mall] = {
    {
      coin_id = curio_emporium_module.top_up_currency_id,
      show_add = false
    }
  },
  [curio_emporium_module.entrance_tag_type.monthly_pass] = {
    {
      coin_id = curio_emporium_module.top_up_currency_id,
      show_add = true
    },
    {coin_id = 200010, show_add = false}
  }
}

function curio_emporium_module:init()
  self._curio_shop_tag_cfgs = nil
  self._curio_shop_top_up_cfgs = nil
  self._gift_unlock_condition_set_by_type = nil
  self._events = {
    [EventID.LuaOnOpenConditionNotify] = pack(self, self._on_open_condition_notify),
    [EventID.OnEmergencySwitchStateChanged] = pack(self, self._on_emergency_switch_changed)
  }
  for event_id, callback in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, callback)
  end
end

function curio_emporium_module:close()
  self:_invalidate_hot_sale_red_point_cache()
  if self._events then
    for event_id, callback in pairs(self._events) do
      EventCenter.LuaRemoveListener(event_id, callback)
    end
    self._events = nil
  end
end

function curio_emporium_module:_on_open_condition_notify(condition_id)
  self:invalidate_hot_sale_red_point_by_unlock_condition(condition_id)
end

function curio_emporium_module:_on_emergency_switch_changed()
  self:_invalidate_hot_sale_red_point_cache()
  EventCenter.Broadcast(EventID.LuaRefreshCurioEmporiumRedPoint, nil)
end

function curio_emporium_module:clear_on_disconnect()
  self._curio_shop_tag_cfgs = nil
  self._curio_shop_top_up_cfgs = nil
  self._curio_shop_gift_cfgs = nil
  self:_invalidate_hot_sale_red_point_cache()
  self._gift_unlock_condition_set_by_type = nil
  self._shown_gift_set = nil
end

return curio_emporium_module
