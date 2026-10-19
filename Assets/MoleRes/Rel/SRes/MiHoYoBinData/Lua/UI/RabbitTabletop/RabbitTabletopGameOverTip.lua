local M = G.Class("RabbitTabletopGameOverTip", G.UIWindow)
local base = G.UIWindow
local item_cls = "UI/RabbitTabletop/RabbitTabletopGameOverItem"
local SHOW_DURATION = 1.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopGameOverTip"
  self.config.type = EUIType.Tip
  self._items = {}
  self._cur_seat = nil
  self._hide_timer = nil
end

function M:on_create()
  base.on_create(self)
  local seat_objs = {
    [1] = self._obj_p1,
    [2] = self._obj_p2,
    [3] = self._obj_p3,
    [4] = self._obj_p4
  }
  for seat, obj in pairs(seat_objs) do
    if not is_null(obj) then
      local item = self:add_panel(item_cls, obj.transform)
      if item then
        item:set_active(false, true)
        self._items[seat] = item
      end
    end
  end
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self:show_seat(data and data.seat_index or 0)
end

function M:on_disable()
  self:_hide_all()
  self._cur_seat = nil
  self._hide_timer = nil
  base.on_disable(self)
end

function M:refresh_seat(seat_index)
  if not next(self._items) then
    return false
  end
  self:show_seat(seat_index)
  return true
end

function M:show_seat(seat_index)
  seat_index = seat_index or 0
  local item = self._items[seat_index]
  if not item then
    Logger.LogWarning("[RabbitTabletopGameOverTip] invalid seat_index: " .. tostring(seat_index))
    self._hide_timer = nil
    self:_hide_all()
    return
  end
  if self._cur_seat and self._cur_seat ~= seat_index then
    local prev = self._items[self._cur_seat]
    if prev then
      prev:set_active(false, true)
    end
  end
  self._cur_seat = seat_index
  self._hide_timer = SHOW_DURATION
  if item.is_active then
    item:set_active(false, true)
  end
  item:set_active(true)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._hide_timer then
    return
  end
  self._hide_timer = self._hide_timer - deltaTime
  if self._hide_timer <= 0 then
    self._hide_timer = nil
    self:_hide_cur_seat()
  end
end

function M:_hide_cur_seat()
  local item = self._cur_seat and self._items[self._cur_seat]
  self._cur_seat = nil
  if item then
    item:set_active(false)
  end
end

function M:_hide_all()
  for _, item in pairs(self._items) do
    item:set_active(false, true)
  end
end

return M
