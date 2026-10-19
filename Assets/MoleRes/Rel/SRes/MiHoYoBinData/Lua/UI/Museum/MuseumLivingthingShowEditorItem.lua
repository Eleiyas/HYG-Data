local M = G.Class("MuseumLivingthingShowEditorItem", G.UIPanel)
local base = G.UIPanel
local item_v2_panel_cls = "UI/Item/ItemV2Panel"

function M:init()
  base.init(self)
  self._config_id = nil
  self._on_click = nil
  self._on_checkbox_click = nil
  self._is_exhibited = false
  self._stars = {}
end

function M:on_create()
  base.on_create(self)
  if not_null(self._obj_item) then
    self._item_panel = self:add_panel(item_v2_panel_cls, self._obj_item.transform)
  end
  if not_null(self._checkbox_dark) then
    self._toggle_exhibit = self._checkbox_dark:GetComponent(typeof(ToggleEx))
    self:bind_callback(self._toggle_exhibit, pack(self, M._on_checkbox_changed))
  end
  if not_null(self._tog_item) then
    self:bind_callback(self._tog_item, pack(self, M._on_tog_item_changed))
  end
end

function M:_on_tog_item_changed(is_on)
  if self._on_click then
    self._on_click(self._config_id, is_on == true)
  end
end

function M:set_select(is_select)
  if not_null(self._tog_item) then
    self._tog_item:SetIsOnWithoutNotify(is_select == true)
  end
end

function M:_on_checkbox_changed()
  self:_set_checkbox(self._is_exhibited)
  if self._on_checkbox_click then
    self._on_checkbox_click(self._config_id)
  end
end

function M:_set_checkbox(is_on)
  if is_null(self._toggle_exhibit) then
    return
  end
  self._toggle_exhibit:SetIsOnWithoutNotify(is_on == true)
end

function M:refresh(item_data)
  self._config_id = item_data.config_id
  self._on_click = item_data.on_click
  self._on_checkbox_click = item_data.on_checkbox_click
  if self._item_panel then
    self._item_panel:set_item_data(self._config_id, 1)
  end
  local item_cfg = item_data.item_cfg
  UIUtil.set_text(self._txt_item_name, not is_null(item_cfg) and item_cfg.name or "")
  self:_refresh_stars(item_data.star_level or 0)
  self:set_exhibit_state(item_data.is_exhibited, item_data.area_name)
  self:set_select(false)
end

function M:set_exhibit_state(is_exhibited, area_name)
  self._is_exhibited = is_exhibited == true
  self:_set_checkbox(self._is_exhibited)
  local show_area = string.is_valid(area_name)
  UIUtil.set_active(self._trans_item_area, show_area)
  if show_area then
    UIUtil.set_text(self._txt_item_area, area_name)
  end
end

function M:_refresh_stars(star_level)
  if is_null(self._item_star) then
    return
  end
  UIUtil.set_active(self._item_star, false)
  local star_parent = self._item_star.transform.parent
  for i = 1, star_level do
    if i > #self._stars then
      table.insert(self._stars, UIUtil.load_prefab_set_parent(self._item_star, star_parent))
    end
    UIUtil.set_active(self._stars[i], true)
  end
  for i = star_level + 1, #self._stars do
    UIUtil.set_active(self._stars[i], false)
  end
end

function M:get_config_id()
  return self._config_id
end

return M
