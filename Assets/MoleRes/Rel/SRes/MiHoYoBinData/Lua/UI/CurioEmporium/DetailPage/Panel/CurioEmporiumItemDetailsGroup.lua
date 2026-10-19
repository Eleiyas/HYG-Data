local M = G.Class("CurioEmporiumItemDetailsGroup", G.UIPanel)
local base = G.UIPanel
local item_cls = "UI/CurioEmporium/DetailPage/Panel/CurioEmporiumItemDetailsItem"

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

function M:refresh(title, items, on_item_selected)
  self._title = title
  self._items = items
  self._on_item_selected = on_item_selected
  self:_refresh_title()
  self:_refresh_items()
end

function M:_refresh_title()
  UIUtil.set_text(self._txt_title, self._title or "")
end

function M:_refresh_items()
  local count = #self._items
  local max_num = math.max(count, #self._item_pool)
  for i = 1, max_num do
    local item = self._item_pool[i]
    if i <= count then
      if not item then
        local obj = self._list_item_binder:AddItem(0)
        if not_null(obj) then
          item = self:add_panel(item_cls, obj)
          self._item_pool[i] = item
        end
      end
      if item then
        item:refresh(self._items[i], self._on_item_selected, self:get_load_proxy())
        UIUtil.set_active(item.game_obj, true)
      end
    elseif item then
      UIUtil.set_active(item.game_obj, false)
    end
  end
end

return M
