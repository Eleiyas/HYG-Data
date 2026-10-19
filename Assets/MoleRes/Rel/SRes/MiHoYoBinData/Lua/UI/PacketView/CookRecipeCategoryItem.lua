local M = G.Class("CookRecipeCategoryItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._category_id = 0
  self._on_select = nil
  self._is_unlocked = false
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog) then
    self:bind_callback(self._tog, pack(self, M._on_tog_changed))
  end
end

function M:_on_tog_changed(is_on)
  if not is_on then
    return
  end
  self:mark_viewed()
  if self._on_select ~= nil then
    self._on_select(self._category_id)
  end
end

function M:refresh(cfg, is_selected, is_unlocked, show_order)
  if is_null(cfg) then
    return
  end
  self._category_id = cfg.id or 0
  self._is_unlocked = is_unlocked == true
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, cfg.desc or "")
  end
  local icon_name = cfg.iconname or ""
  if not_null(self._img_icon) and string.is_valid(icon_name) then
    UIUtil.set_image(self._img_icon, icon_name, self:get_load_proxy())
  end
  if is_selected then
    self:mark_viewed()
  end
  local show_red = self:_is_category_red()
  if not_null(self._img_order) then
    UIUtil.set_active(self._img_order, show_order == true and not show_red)
  end
  if not_null(self._tog) and self._tog.SetIsOnWithoutNotify then
    self._tog:SetIsOnWithoutNotify(is_selected == true)
  elseif not_null(self._tog) then
    self._tog.isOn = is_selected == true
  end
  self:refresh_red()
end

function M:_is_category_red()
  if self._category_id <= 0 or not self._is_unlocked then
    return false
  end
  return not red_point_module:is_recorded_with_id(red_point_module.red_point_type.cook_recipe_category, self._category_id)
end

function M:mark_viewed()
  if self._category_id <= 0 or not self._is_unlocked then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.cook_recipe_category, self._category_id)
  self:refresh_red()
end

function M:refresh_red()
  if is_null(self._red_point) then
    return
  end
  self._red_point:ShowRedPoint(self:_is_category_red() and RedPointType.NewRp or RedPointType.None)
end

function M:set_select_callback(cb)
  self._on_select = cb
end

function M:get_category_id()
  return self._category_id
end

function M:set_selected(is_selected)
  if is_selected then
    self:mark_viewed()
  end
  if not_null(self._tog) and self._tog.SetIsOnWithoutNotify then
    self._tog:SetIsOnWithoutNotify(is_selected)
  elseif not_null(self._tog) then
    self._tog.isOn = is_selected
  end
end

return M
