local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("TagGroupListSection", base_path)
local base = G.DetailSectionBase
local tag_group_section_class = "UI/Codex/DetailPage/V2/Sections/TagGroupSection"

function M:on_create()
  base.on_create(self)
  self._section_panels = {}
  self._list_parent = self._trans_tag_group_section.parent
  self._trans_tag_group_section.gameObject:SetActive(false)
end

function M:should_show(item_data)
  local tags = self:_get_tags(item_data)
  return tags and 0 < #tags
end

function M:refresh(item_data)
  local tags = self:_get_tags(item_data)
  for i, tag_data in ipairs(tags) do
    local panel = self:_get_or_create(i)
    panel:set_active(true)
    panel:refresh_tag(tag_data)
  end
  for i = #tags + 1, #self._section_panels do
    self._section_panels[i]:set_active(false)
  end
end

function M:_get_tags(item_data)
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  return strategy.get_detail_tags and strategy:get_detail_tags(item_data) or {}
end

function M:_get_or_create(index)
  if self._section_panels[index] then
    return self._section_panels[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_tag_group_section.gameObject, self._list_parent)
  local panel = self:add_panel(tag_group_section_class, go.transform)
  self._section_panels[index] = panel
  return panel
end

return M
