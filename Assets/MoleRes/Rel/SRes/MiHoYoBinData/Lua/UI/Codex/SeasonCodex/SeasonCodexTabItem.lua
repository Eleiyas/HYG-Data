local M = G.Class("SeasonCodexTabItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._category = nil
  self._icon_path = nil
  self._on_selected = nil
  self._red_point = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_category_1) then
    self:bind_callback(self._tog_category_1, pack(self, M._on_toggle_changed))
  end
end

function M:setup(category, icon_path, on_selected, red_point_template)
  self._category = category
  self._icon_path = icon_path
  self._on_selected = on_selected
  if not_null(self._img_tab_icon) and icon_path and icon_path ~= "" then
    UIUtil.set_image(self._img_tab_icon, icon_path, self:get_load_proxy())
  end
  self:_init_red_point(red_point_template)
end

function M:_init_red_point(red_point_template)
  if is_null(red_point_template) or is_null(self._img_tab_icon) then
    return
  end
  local go = UIUtil.load_prefab_set_parent(red_point_template.gameObject, self._img_tab_icon.transform)
  if is_null(go) then
    return
  end
  go.name = "RedPoint"
  local rect = go:GetComponent(typeof(RectTransform))
  if not_null(rect) then
    rect.anchorMin = Vector2(1, 1)
    rect.anchorMax = Vector2(1, 1)
    rect.anchoredPosition = Vector2(0, 0)
  end
  UIUtil.set_active(go, true)
  self._red_point = go:GetComponent(typeof(MonoRedPointContainer))
end

function M:refresh_red_point(has_new)
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(has_new and RedPointType.NewRp or RedPointType.None)
  end
end

function M:set_selected(is_on)
  if not_null(self._tog_category_1) then
    self._tog_category_1.isOn = is_on
  end
end

function M:_on_toggle_changed(is_on)
  if is_on and self._on_selected and self._category ~= nil then
    self._on_selected(self._category)
  end
end

return M
