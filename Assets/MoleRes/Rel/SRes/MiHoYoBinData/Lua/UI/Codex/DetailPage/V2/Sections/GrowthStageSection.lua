local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local item_class = "UI/Codex/DetailPage/V2/Sections/GrowthStageSectionItem"
local M = G.Class("GrowthStageSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self._item_panels = {}
  self._item_template = nil
  if not_null(self._trans_item) then
    self._item_template = self._trans_item
    UIUtil.set_active(self._item_template, false)
    self:_get_or_create_item(1)
  end
end

function M:should_show(item_data)
  local panel = self._item_panels[1]
  if not panel or not panel:can_render() then
    return false
  end
  local galaxies = self:_list_weed_galaxies(item_data)
  if galaxies then
    return true
  end
  return panel:has_content(item_data)
end

function M:refresh(item_data)
  local galaxies = self:_list_weed_galaxies(item_data)
  if galaxies then
    self:_refresh_weed_galaxies(item_data, galaxies)
    return
  end
  local panel = self:_get_or_create_item(1)
  if not panel then
    return
  end
  panel:set_active(true)
  panel:refresh(item_data)
  self:_hide_items_from(2)
end

function M:_list_weed_galaxies(item_data)
  if not self:_is_weed(item_data) then
    return nil
  end
  local gatherable = item_data and item_data.GatherableDetail
  if is_null(gatherable) then
    return nil
  end
  local galaxy_list = gatherable.GalaxyStageList
  if is_null(galaxy_list) or galaxy_list.Count == 0 then
    return nil
  end
  local galaxies = {}
  for i = 0, galaxy_list.Count - 1 do
    local galaxy_data = galaxy_list[i]
    if not_null(galaxy_data) and not_null(galaxy_data.StageTimes) and 0 < galaxy_data.StageTimes.Count then
      table.insert(galaxies, galaxy_data)
    end
  end
  if #galaxies == 0 then
    return nil
  end
  table.sort(galaxies, function(a, b)
    return (a.GalaxyId or 0) < (b.GalaxyId or 0)
  end)
  return galaxies
end

function M:_is_weed(item_data)
  local server_data = item_data and item_data.ServerData
  local id = server_data and server_data.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.organism_plant_lowplant_grass)
end

function M:_refresh_weed_galaxies(item_data, galaxies)
  for i = 1, #galaxies do
    self:_get_or_create_item(i)
  end
  for i, galaxy_data in ipairs(galaxies) do
    local panel = self._item_panels[i]
    if panel then
      panel:set_active(true)
      panel:refresh(item_data, galaxy_data)
    end
  end
  self:_hide_items_from(#galaxies + 1)
end

function M:_get_or_create_item(index)
  if self._item_panels[index] then
    return self._item_panels[index]
  end
  if is_null(self._item_template) then
    return nil
  end
  local go = UIUtil.load_prefab_set_parent(self._item_template.gameObject, self._item_template.parent)
  local panel = self:add_panel(item_class, go.transform)
  self._item_panels[index] = panel
  return panel
end

function M:_hide_items_from(start_index)
  for i = start_index, #self._item_panels do
    self._item_panels[i]:set_active(false)
  end
end

return M
