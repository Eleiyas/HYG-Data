local base = require("UI/Gacha/GachaDrawShowPage")
local M = G.Class("GachaDrawShowT0Page", base)
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local item_in_interval = 0.06

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.draw_show_t0
  self.config.type = EUIType.Page
  self._show_items = nil
  self._show_tween = nil
  self._is_enabled = false
end

function M:on_enable()
  base.on_enable(self)
  self._is_enabled = true
  self:_start_item_show()
end

function M:on_disable()
  self._is_enabled = false
  self:_stop_item_show()
  base.on_disable(self)
end

function M:on_destroy()
  self:_stop_item_show()
  self._show_items = nil
  base.on_destroy(self)
end

function M:refresh_item_active(cls)
  cls:set_active(false)
end

function M:on_items_refreshed(items)
  self:_stop_item_show()
  self._show_items = nil
  local count = items ~= nil and #items or 0
  if count <= 0 then
    return
  end
  local show_items = {}
  for i = 1, count do
    show_items[i] = items[i]
  end
  self._show_items = show_items
  self:_start_item_show()
end

function M:_start_item_show()
  if not (self._show_items ~= nil and self._show_tween == nil and self.is_active) or not self._is_enabled then
    return
  end
  local count = #self._show_items
  self:_play_item_in(1, count == 1)
  if count <= 1 then
    return
  end
  local tween = DOTween.Sequence()
  for i = 2, count do
    tween:AppendInterval(item_in_interval)
    tween:AppendCallback(function()
      self:_play_item_in(i, i == count)
    end)
  end
  self._show_tween = tween
end

function M:_stop_item_show()
  if self._show_tween == nil then
    return
  end
  self._show_tween:Kill()
  self._show_tween = nil
end

function M:_play_item_in(index, is_last)
  local items = self._show_items
  local item = items and items[index]
  local is_started = false
  if item ~= nil and not_null(item.game_obj) then
    item:set_active(true)
    local on_complete
    if is_last then
      function on_complete()
        self:_on_items_in_finished()
      end
    end
    is_started = item:play_in_anim(on_complete)
  end
  if is_last and not is_started then
    self:_on_items_in_finished()
  end
end

function M:_on_items_in_finished()
  local items = self._show_items
  self._show_items = nil
  self:_stop_item_show()
  self:_check_all_collect()
  if items == nil then
    return
  end
  for _, item in ipairs(items) do
    if not_null(item.game_obj) then
      item:play_repeat_anim()
    end
  end
end

function M:refresh_coin(gacha_id)
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local exchange_coin_id = activity_cfg.exchangeshopcoinid or 0
  if is_null(self._obj_coin_item) then
    return
  end
  if self._coin_item == nil then
    self._coin_item = self:add_panel(coin_item_view_cls, self._obj_coin_item, {
      coin_id = exchange_coin_id,
      auto_update = true,
      show_detail = true
    })
    self._coin_item_coin_id = exchange_coin_id
  elseif self._coin_item_coin_id ~= exchange_coin_id then
    self._coin_item:set_coin_id(exchange_coin_id)
    self._coin_item_coin_id = exchange_coin_id
  end
end

function M:_close_handler()
  if self.holder ~= nil then
    self.holder:close_self()
  else
    base._close_handler(self)
  end
end

return M
