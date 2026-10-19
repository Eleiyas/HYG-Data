local M = G.Class("TagGroupSection", G.UIPanel)
local base = G.UIPanel
local tag_group_item_class = "UI/Codex/DetailPage/V2/Sections/TagGroupItem"

function M:on_create()
  base.on_create(self)
  self._item_panels = {}
  self._trans_tag_group_item.gameObject:SetActive(false)
end

function M:refresh_tag(tag_data)
  local title = tag_data.title_text or tag_data.title_id and UIUtil.get_text_by_id(tag_data.title_id) or ""
  UIUtil.set_text(self._txt_title, title)
  local has_state_group = self._ui_state_group ~= nil and not_null(self._ui_state_group)
  if tag_data.floor_area and has_state_group then
    self._ui_state_group:SetState(1)
    if self._trans_floor_area ~= nil and not_null(self._trans_floor_area) then
      local fa = tag_data.floor_area
      self._trans_floor_area:SetLocalScale(math.min(fa.x, 3), math.min(fa.y, 3), 1)
    end
  else
    if has_state_group then
      self._ui_state_group:SetState(tag_data.no_icon and 2 or 0)
    end
    if self._img_icon ~= nil and not_null(self._img_icon) then
      UIUtil.set_active(self._img_icon, true)
      if tag_data.icon and tag_data.icon ~= "" then
        UIUtil.set_image(self._img_icon, tag_data.icon, self:get_load_proxy())
      end
    end
  end
  local values
  if tag_data.values then
    values = tag_data.values
  else
    values = {
      tag_data.value or ""
    }
  end
  for i, v in ipairs(values) do
    local panel = self:_get_or_create_item(i)
    panel:set_active(true)
    panel:refresh(v)
  end
  for i = #values + 1, #self._item_panels do
    self._item_panels[i]:set_active(false)
  end
end

function M:_get_or_create_item(index)
  if self._item_panels[index] then
    return self._item_panels[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_tag_group_item.gameObject, self._trans_tag_group_item.parent)
  local panel = self:add_panel(tag_group_item_class, go.transform)
  self._item_panels[index] = panel
  return panel
end

return M
