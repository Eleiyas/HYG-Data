local M = G.Class("HairDyeingExchangeItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._color_id = nil
  self._style_id = nil
  self._pickable = false
  self._on_click = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_select, pack(self, M._on_btn_select))
end

function M:refresh(data)
  self._color_id = data.color_id
  self._style_id = data.style_id
  self._pickable = data.pickable == true
  UIUtil.set_image_color(self._img_color, CsDyeingModuleUtil.GetDisplayColorByColorBlockId(self._color_id))
  UIUtil.set_active(self._go_unpickable, not self._pickable)
  self:set_selected(false)
end

function M:set_selected(is_select)
  self._state_group_select:SetState(is_select and 1 or 0)
end

function M:get_color_id()
  return self._color_id
end

function M:get_style_id()
  return self._style_id
end

function M:is_pickable()
  return self._pickable
end

function M:set_on_click(callback)
  self._on_click = callback
end

function M:_on_btn_select()
  if self._on_click then
    self._on_click(self._color_id, self._style_id, self._pickable)
  end
end

return M
