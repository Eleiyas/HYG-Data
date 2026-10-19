local stage_item_class = "UI/Codex/DetailPage/V2/Sections/GrowthStageItem"
local hybrid_item_class = "UI/Codex/DetailPage/V2/Sections/GrowthStageHybridItem"
local M = G.Class("GrowthStageSectionItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._stage_panels = {}
  self._seed_panel = nil
  self._hybrid_panel = nil
  self._default_title = not_null(self._txt_title_state_seed) and self._txt_title_state_seed.text or ""
  if not_null(self._item_stage_template) then
    self._item_stage_template.gameObject:SetActive(false)
  end
  if not_null(self._item_seed) then
    self._seed_panel = self:add_panel(stage_item_class, self._item_seed)
    self._seed_panel:set_active(false)
  end
  if not_null(self._trans_item_hybridization) then
    self._hybrid_panel = self:add_panel(hybrid_item_class, self._trans_item_hybridization)
    self._hybrid_panel:set_active(false)
  end
end

function M:can_render()
  return not_null(self._stage_content) and not_null(self._item_stage_template)
end

function M:has_content(item_data)
  if not self:can_render() then
    return false
  end
  local stages = self:_collect_stages(item_data)
  return stages ~= nil and 0 < #stages
end

function M:refresh(item_data, galaxy_data)
  if not self:can_render() then
    return
  end
  if not_null(galaxy_data) then
    self:_refresh_weed_galaxy(galaxy_data)
    return
  end
  self:_set_default_title()
  self:_refresh_stages(self:_collect_stages(item_data))
end

function M:_refresh_stages(stages)
  UIUtil.set_active(self._stage_content, true)
  local count = stages and #stages or 0
  local seed_data
  local non_seed_stages = {}
  for i = 1, count do
    local stage_data = stages[i]
    if stage_data.is_seed or stage_data.is_hybrid then
      seed_data = stage_data
    else
      table.insert(non_seed_stages, stage_data)
    end
  end
  local is_seed_handled = self:_refresh_seed_stage(seed_data, #non_seed_stages == 0)
  local dynamic_stages = {}
  if seed_data and not is_seed_handled then
    table.insert(dynamic_stages, seed_data)
  end
  for _, stage_data in ipairs(non_seed_stages) do
    table.insert(dynamic_stages, stage_data)
  end
  self:_refresh_dynamic_stages(dynamic_stages)
end

function M:_refresh_seed_stage(seed_data, is_last)
  if seed_data and seed_data.is_hybrid and self._hybrid_panel then
    self._hybrid_panel:set_active(true)
    self._hybrid_panel:refresh({
      first_time = seed_data.first_time
    })
    if self._seed_panel then
      self._seed_panel:set_active(false)
    end
    return true
  end
  if self._hybrid_panel then
    self._hybrid_panel:set_active(false)
  end
  if not self._seed_panel then
    return false
  end
  if not seed_data then
    self._seed_panel:set_active(false)
    return false
  end
  self._seed_panel:set_active(true)
  self._seed_panel:refresh({
    entity_id = seed_data.entity_id,
    first_time = seed_data.first_time,
    is_last = is_last,
    is_seed = seed_data.is_seed == true,
    is_hybrid = seed_data.is_hybrid == true
  })
  return true
end

function M:_refresh_dynamic_stages(stages)
  for i, stage_data in ipairs(stages) do
    local panel = self:_get_or_create_stage(i)
    if panel then
      panel:set_active(true)
      panel:refresh({
        entity_id = stage_data.entity_id,
        first_time = stage_data.first_time,
        is_last = i == #stages,
        is_seed = stage_data.is_seed == true,
        is_hybrid = stage_data.is_hybrid == true
      })
    end
  end
  for i = #stages + 1, #self._stage_panels do
    self._stage_panels[i]:set_active(false)
  end
end

function M:_refresh_weed_galaxy(galaxy_data)
  self:_set_galaxy_title(galaxy_data.GalaxyId)
  if self._seed_panel then
    self._seed_panel:set_active(false)
  end
  if self._hybrid_panel then
    self._hybrid_panel:set_active(false)
  end
  UIUtil.set_active(self._stage_content, true)
  local stage_times = galaxy_data.StageTimes
  local count = not_null(stage_times) and stage_times.Count or 0
  for i = 0, count - 1 do
    local entry = stage_times[i]
    local panel = self:_get_or_create_stage(i + 1)
    if panel then
      panel:set_active(true)
      panel:refresh({
        entity_id = entry.EntityConfigId,
        first_time = entry.FirstSeenTime,
        is_last = i == count - 1
      })
    end
  end
  for i = count + 1, #self._stage_panels do
    self._stage_panels[i]:set_active(false)
  end
end

function M:_set_galaxy_title(galaxy_id)
  if is_null(self._txt_title_state_seed) then
    return
  end
  local galaxy_cfg = ExcelDataUtil.get_value(typeof(BStellarSeaGalaxyCfg), galaxy_id)
  local title = not_null(galaxy_cfg) and galaxy_cfg.galaxyname or tostring(galaxy_id)
  UIUtil.set_text(self._txt_title_state_seed, title)
end

function M:_set_default_title()
  if not_null(self._txt_title_state_seed) then
    UIUtil.set_text(self._txt_title_state_seed, self._default_title)
  end
end

function M:_collect_stages(item_data)
  if is_null(item_data) or is_null(item_data.ServerData) then
    return nil
  end
  if self:_is_weed(item_data) then
    return nil
  end
  if self:_is_mushroom(item_data) then
    return self:_collect_mushroom_stages(item_data)
  end
  local server_data = item_data.ServerData
  if not_null(server_data.CropPlant) then
    return self:_collect_crop_stages(server_data.CropPlant, item_data)
  end
  if not_null(server_data.FlowerItem) then
    return self:_collect_flower_stages(server_data.FlowerItem, item_data)
  end
  if not_null(server_data.MatureTree) then
    return self:_collect_tree_stages(server_data.MatureTree, item_data)
  end
  return nil
end

function M:_is_weed(item_data)
  local server_data = item_data.ServerData
  local id = server_data and server_data.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.organism_plant_lowplant_grass)
end

function M:_is_mushroom(item_data)
  local server_data = item_data.ServerData
  local id = server_data and server_data.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.organism_plant_lowplant_mushroom)
end

function M:_collect_mushroom_stages(item_data)
  local codex_id = item_data.ServerData and item_data.ServerData.Id or 0
  if codex_id == 0 then
    return nil
  end
  return {
    {
      entity_id = codex_id,
      first_time = item_data.IsUnlocked and 1 or 0
    }
  }
end

function M:_seed_first_time(raw_time, item_data)
  if 0 < (raw_time or 0) then
    return raw_time
  end
  local server_data = item_data and item_data.ServerData
  if server_data and 0 < (server_data.TotalObtainedCount or 0) then
    return 1
  end
  return 0
end

function M:_collect_crop_stages(crop_data, item_data)
  local stages = {}
  local seed_id = crop_data.SeedItemId
  if seed_id == 0 then
    seed_id = item_data.SeedItemId
  end
  local crop_cfg
  if 0 < seed_id then
    crop_cfg = ExcelDataUtil.get_value(typeof(BCropPlantCfg), seed_id)
    table.insert(stages, {
      entity_id = seed_id,
      first_time = self:_seed_first_time(crop_data.FirstSeedObtainedTime, item_data),
      is_seed = true
    })
  end
  local server_times = {}
  local seedling_times = crop_data.StageSeedlingTimes
  if not_null(seedling_times) then
    for i = 0, seedling_times.Count - 1 do
      local entry = seedling_times[i]
      if not_null(entry) then
        server_times[entry.EntityConfigId] = entry.FirstPlantTime
      end
    end
  end
  if not_null(crop_cfg) then
    local non_first_round_count = crop_cfg.nonfirstroundseedlingidlistLength
    if 0 < non_first_round_count then
      for i = 0, non_first_round_count - 1 do
        local entity_id = crop_cfg:nonfirstroundseedlingidlist(i)
        if 0 < entity_id then
          table.insert(stages, {
            entity_id = entity_id,
            first_time = server_times[entity_id] or 0
          })
        end
      end
    else
      local first_round_count = crop_cfg.stageseedlingidlistLength
      for i = 0, first_round_count - 1 do
        local entity_id = crop_cfg:stageseedlingidlist(i)
        if 0 < entity_id then
          table.insert(stages, {
            entity_id = entity_id,
            first_time = server_times[entity_id] or 0
          })
        end
      end
    end
    local fruit_count = crop_cfg.fruitplantidlistLength
    if 0 < fruit_count then
      table.insert(stages, {
        entity_id = crop_cfg:fruitplantidlist(0),
        first_time = crop_data.FruitPlantFirstTime or 0
      })
    end
  end
  return 0 < #stages and stages or nil
end

function M:_is_hybrid_flower(item_data)
  local id = item_data and item_data.ServerData and item_data.ServerData.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.otherplanttype_hybridflower)
end

function M:_collect_flower_stages(flower_data, item_data)
  local stages = {}
  local codex_id = item_data and item_data.ServerData and item_data.ServerData.Id or 0
  local is_hybrid = self:_is_hybrid_flower(item_data)
  if is_hybrid then
    table.insert(stages, {
      entity_id = 0,
      first_time = 0 < (item_data.ServerData.TotalObtainedCount or 0) and 1 or 0,
      is_hybrid = true
    })
  else
    local seed_id = flower_data.SeedItemId
    if seed_id and 0 < seed_id then
      table.insert(stages, {
        entity_id = seed_id,
        first_time = self:_seed_first_time(flower_data.FirstSeedObtainedTime, item_data),
        is_seed = true
      })
    end
  end
  local server_times = {}
  local stage_times = flower_data.StagePlantTimes
  if not_null(stage_times) then
    for i = 0, stage_times.Count - 1 do
      local entry = stage_times[i]
      if not_null(entry) then
        server_times[entry.EntityConfigId] = entry.FirstPlantTime
      end
    end
  end
  local bloom_id = codex_module:get_flower_bloom_id(codex_id)
  if is_hybrid and bloom_id then
    local flower_cfg = ExcelDataUtil.get_value(typeof(BFlowerDropCfg), bloom_id)
    if not_null(flower_cfg) then
      if 0 < flower_cfg.budid then
        table.insert(stages, {
          entity_id = flower_cfg.budid,
          first_time = server_times[flower_cfg.budid] or 0
        })
      end
      table.insert(stages, {
        entity_id = bloom_id,
        first_time = server_times[bloom_id] or 0
      })
    end
  else
    local cfg_chain = codex_module:get_plant_stage_chain(bloom_id)
    if cfg_chain and 0 < #cfg_chain then
      for _, entity_id in ipairs(cfg_chain) do
        table.insert(stages, {
          entity_id = entity_id,
          first_time = server_times[entity_id] or 0
        })
      end
    else
      for entity_id, first_time in pairs(server_times) do
        table.insert(stages, {entity_id = entity_id, first_time = first_time})
      end
    end
  end
  return 0 < #stages and stages or nil
end

function M:_collect_tree_stages(tree_data, item_data)
  local stages = {}
  local seed_id = tree_data.SeedItemId
  if seed_id and 0 < seed_id then
    table.insert(stages, {
      entity_id = seed_id,
      first_time = self:_seed_first_time(tree_data.FirstSeedObtainedTime, item_data),
      is_seed = true
    })
  end
  local stage_times = tree_data.StageTimes
  if not_null(stage_times) then
    for i = 0, stage_times.Count - 1 do
      local entry = stage_times[i]
      if not_null(entry) then
        table.insert(stages, {
          entity_id = entry.EntityConfigId,
          first_time = entry.FirstSeenTime
        })
      end
    end
  end
  return 0 < #stages and stages or nil
end

function M:_get_or_create_stage(index)
  if self._stage_panels[index] then
    return self._stage_panels[index]
  end
  if not self:can_render() then
    return nil
  end
  local go = UIUtil.load_prefab_set_parent(self._item_stage_template.gameObject, self._stage_content)
  local panel = self:add_panel(stage_item_class, go.transform)
  self._stage_panels[index] = panel
  return panel
end

return M
