local M = G.Class("NpcClothMachineCategoryItem", G.UIBase)
local base = G.UIBase
local CATEGORY_STOCK_STATE_IN_STOCK = 0

function M:on_create()
  base.on_create(self)
  self._toggle = self._tog_category or self._tog
  if self._toggle then
    self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
  else
    Logger.LogError("[NpcClothMachineCategoryItem] missing binder _tog_category or _tog")
  end
end

function M:refresh(data, context)
  self._data = data
  self._context = context or {}
  if is_null(data) then
    self:set_active(false)
    return
  end
  self:set_active(true)
  if self._txt_name then
    UIUtil.set_text(self._txt_name, data.title or data.name or "")
  end
  local has_icon = string.is_valid(data.icon)
  self:_refresh_icon(self._img_icon or self._img_select_icon, data.icon, has_icon)
  self:_refresh_icon(self._img_unselect_icon, data.icon, has_icon)
  if not_null(self._state_group_stock) then
    self._state_group_stock:SetState(data.stock_state or CATEGORY_STOCK_STATE_IN_STOCK)
  end
  self:_set_selected(data.category_id == self._context.current_category_id)
  self:_set_interactable(data.interactable ~= false)
end

function M:_refresh_icon(img, icon, has_icon)
  if is_null(img) then
    return
  end
  UIUtil.set_active(img, has_icon)
  if has_icon then
    UIUtil.set_image(img, icon, self:get_load_proxy())
  end
end

function M:_set_selected(is_selected)
  if self._toggle and self._toggle.SetIsOnWithoutNotify then
    self._toggle:SetIsOnWithoutNotify(is_selected == true)
  end
end

function M:_set_interactable(is_interactable)
  if self._toggle then
    self._toggle.interactable = is_interactable == true
  end
  if self._canvas_group then
    self._canvas_group.alpha = is_interactable == true and 1 or 0.35
    self._canvas_group.interactable = is_interactable == true
  end
end

function M:_on_toggle_changed(is_on)
  if not self._data or self._data.interactable == false then
    return
  end
  if not is_on then
    self._toggle:SetIsOnWithoutNotify(true)
    return
  end
  if self._context and self._context.on_click_category then
    self._context.on_click_category(self._data.category_id, self._data)
  end
end

return M
