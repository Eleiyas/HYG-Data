local M = G.Class("StarExploreResultPanel", G.UIPanel)
local base = G.UIPanel
local first_stage_duration_seconds = 3
local result_stage_state = {first = 0, second = 1}
local new_area_state = {has_new_area = 0, no_new_area = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExplore/StarExploreResultPanel"
  self._is_created = false
  self._is_finished = false
  self._stage_timer = nil
end

function M:on_create()
  base.on_create(self)
  self._is_created = true
  self._stage_timer = nil
  self._island_items = {}
  self._star_cfg_by_name = nil
  self:bind_callback(self._btn_confirm, pack(self, M._on_confirm_click))
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  if self._is_finished then
    self._show_state:SetState(result_stage_state.second)
    return
  end
  self:refresh_view()
  self:_restart_stage_timer()
end

function M:on_disable()
  self:_stop_stage_timer()
  base.on_disable(self)
end

function M:on_close()
  self:_stop_stage_timer()
  base.on_close(self)
end

function M:on_destroy()
  self._is_created = false
  self:_stop_stage_timer()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:refresh_view()
  local progress = star_explore_module:get_left_item_data()
  if is_null(progress) then
    self:_refresh_new_area({})
    self:_refresh_new_islands({})
    return
  end
  self:_refresh_new_area(list_to_table(progress.ReachedNewLayerIdList) or {})
  self:_refresh_new_islands(dic_to_table(progress.NewIslandDict) or {})
end

function M:reset_result()
  self._is_finished = false
  if not self._is_created then
    return
  end
  self._show_state:SetState(result_stage_state.first)
end

function M:finish()
  self._is_finished = true
  self:_stop_stage_timer()
  if self._is_created then
    self._show_state:SetState(result_stage_state.second)
  end
end

function M:_refresh_new_area(reached_new_layer_ids)
  local layer_names = {}
  for _, layer_id in ipairs(reached_new_layer_ids) do
    local layer_cfg = ExcelDataUtil.get_value(typeof(BStellarSeaLayerCfg), layer_id)
    if not_null(layer_cfg) and string.is_valid(layer_cfg.name) then
      table.insert(layer_names, layer_cfg.name)
    end
  end
  local area_count = #layer_names
  local has_new_area = 0 < area_count
  self._new_area_state:SetState(has_new_area and new_area_state.has_new_area or new_area_state.no_new_area)
  local area_text = ""
  if area_count == 1 then
    area_text = UIUtil.get_text_by_id("StellarSea_TravelAreaCount_1", tostring(layer_names[1]))
  elseif area_count == 2 then
    area_text = UIUtil.get_text_by_id("StellarSea_TravelAreaCount_2", layer_names[1], layer_names[2])
  elseif area_count == 3 then
    area_text = UIUtil.get_text_by_id("StellarSea_TravelAreaCount_3", layer_names[1], layer_names[2], layer_names[3])
  end
  UIUtil.set_text(self._txt_new_area, area_text)
end

function M:_refresh_new_islands(new_island_dict)
  local island_icons = {}
  local new_island_count = 0
  local star_cfg_by_name = self:_get_star_cfg_by_name()
  for island_name, count in pairs(new_island_dict) do
    local island_count = math.max(math.floor(tonumber(count) or 0), 0)
    new_island_count = new_island_count + island_count
    local star_cfg = star_cfg_by_name[island_name]
    if star_cfg and string.is_valid(star_cfg.islandshotcut) then
      for _ = 1, island_count do
        table.insert(island_icons, {
          config_id = star_cfg.id,
          icon = star_cfg.islandshotcut
        })
      end
    end
  end
  table.sort(island_icons, function(a, b)
    return a.config_id < b.config_id
  end)
  UIUtil.set_text(self._txt_island_num, TextMapFormatUtil.FormatInteger(new_island_count))
  self:_refresh_island_list(island_icons)
end

function M:_get_star_cfg_by_name()
  if self._star_cfg_by_name then
    return self._star_cfg_by_name
  end
  self._star_cfg_by_name = {}
  local star_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaStarCfg)) or {}
  for _, star_cfg in pairs(star_cfg_table) do
    local island_name = star_cfg.name
    local current_cfg = self._star_cfg_by_name[island_name]
    if string.is_valid(island_name) and (not current_cfg or star_cfg.id < current_cfg.id) then
      self._star_cfg_by_name[island_name] = star_cfg
    end
  end
  return self._star_cfg_by_name
end

function M:_refresh_island_list(island_icons)
  local max_item_count = math.max(#self._island_items, #island_icons)
  for item_index = 1, max_item_count do
    local island_data = island_icons[item_index]
    local island_item = self._island_items[item_index]
    if not island_item and island_data then
      local item_transform = self._island_list:AddItem(0)
      if not_null(item_transform) then
        island_item = {
          transform = item_transform,
          image = UIUtil.find_cmpt(item_transform, "mask/img_icon_dynamic", typeof(ImageEx)),
          icon = UIUtil.find_cmpt(item_transform, "img_icon_dynamic", typeof(ImageEx)),
          name = UIUtil.find_cmpt(item_transform, "txt_island_name_dynamic", typeof(TextEx))
        }
        self._island_items[item_index] = island_item
      end
    end
    if island_item then
      UIUtil.set_active(island_item.transform, island_data ~= nil)
      if island_data and not_null(island_item.image) then
        UIUtil.set_image(island_item.image, island_data.icon, self:get_load_proxy())
        local star_cfg = ExcelDataUtil.get_value(typeof(BStellarSeaStarCfg), island_data.config_id)
        if not_null(star_cfg) then
          local icon_cfg = ExcelDataUtil.get_value(typeof(BStarIslandIconCfg), star_cfg.radartrackingtypeid)
          UIUtil.set_text(island_item.name, star_cfg.name)
          if not_null(icon_cfg) then
            UIUtil.set_image(island_item.icon, icon_cfg.iconsettlement, self:get_load_proxy())
          end
        end
      end
    end
  end
end

function M:_restart_stage_timer()
  self:_stop_stage_timer()
  self._show_state:SetState(result_stage_state.first)
  self._stage_timer = CsTimerManagerUtil.StartTimer(first_stage_duration_seconds, function()
    self._stage_timer = nil
    if not self._is_created or self._is_finished then
      return
    end
    self._show_state:SetState(result_stage_state.second)
  end)
end

function M:_stop_stage_timer()
  if self._stage_timer == nil then
    return
  end
  CsTimerManagerUtil.StopTimer(self._stage_timer)
  self._stage_timer = nil
end

function M:_on_confirm_click()
  self:_enter_collection_display()
end

function M:_enter_collection_display()
  self:finish()
  local extra_data = self:get_extra_data()
  if extra_data and extra_data.on_confirm then
    extra_data.on_confirm()
  end
end

return M
