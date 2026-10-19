local M = G.Class("StarExploreTeleportationPage", G.UIWindow)
local base = G.UIWindow
local ADD_MAX_RATIO = 3
local MINUS_MAX_RATIO = 1
local DEFAULT_RATIO = 2
local STEP_RATIO = 0.1
local MAP_POS_RATIO = 2
local ISLAND_DEFAULT_ICON = "UISprite/Load/MaterialStar/Icon_MaterialStar_StarCoin.png"
local MAP_FADE_TIME = 0.15

local function _is_unrevealed_gate(gate)
  return gate ~= nil and gate.IsSpecial == true and gate.IsInspected ~= true
end

local function _station_entity_id(station)
  if station == nil then
    return nil
  end
  if station.Guid ~= nil and station.Guid ~= 0 then
    return station.Guid
  end
  return station.ClientGuid
end

local function _is_valid_entity_id(id)
  return id ~= nil and id ~= 0
end

local function _station_match_level(place_data, info)
  if place_data == nil or info == nil or info.iconType ~= 4 then
    return 0
  end
  if _is_valid_entity_id(place_data.entityId) and _is_valid_entity_id(info.entityId) and place_data.entityId == info.entityId then
    return 2
  end
  if place_data.layerCfgId ~= nil and place_data.layerCfgId == info.layerCfgId then
    return 1
  end
  return 0
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MaterialStarExplore/StarExploreTeleportationPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._trans_ani_right) then
    self._trans_ani_right:SetActive(false)
    self._teleportation_detail_panel = self:add_panel("UI/StarExplore/StarExploreTeleportationDetail", self._trans_ani_right.gameObject)
  end
end

function M:on_open()
  base.on_open(self)
  local data = self:get_extra_data() or {}
  self._light_house_guid = data.light_house_guid
  self._is_outside = data.is_outside_star_sea == true
  self._galaxy_id = CsStarSeaManagerV2Util.GetGalaxyId()
  self._home_layer = not self._is_outside and self:_get_home_layer_cfg_id() or 0
  self._cur_layer = self._home_layer
  self._current_station_guid = not self._is_outside and self:_get_current_station_guid() or nil
  self._map_hidden = false
  if self._teleportation_detail_panel ~= nil then
    self._teleportation_detail_panel:set_active(false, true)
  elseif not is_null(self._trans_ani_right) then
    self._trans_ani_right:SetActive(false)
  end
  self:_init_slider()
  self:_refresh_place_items()
  local default_layer = self._is_outside and self:_get_first_season_layer() or self._home_layer
  self:_switch_layer(default_layer, true)
  self:_select_place_item(default_layer)
end

function M:_select_place_item(layer_cfg_id)
  for i = 1, self._place_item_count or 0 do
    local item = self._place_item_entries[i]
    local data = item ~= nil and item._data or nil
    if data ~= nil and data.layerCfgId == layer_cfg_id and not is_null(item._tog) then
      item._tog.isOn = true
      return
    end
  end
end

function M:_get_first_season_layer()
  local layer_ids = CsStarSeaManagerV2Util.GetSeasonPreviewLayerIdList()
  if is_null(layer_ids) then
    return 0
  end
  return list_to_table(layer_ids)[1] or 0
end

function M:_get_home_layer_cfg_id()
  local galaxy_id = CsStarSeaManagerV2Util.GetGalaxyId()
  local layer = CsStarSeaManagerV2Util.GetLayerId()
  local layer_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaLayerCfg)) or {}
  for _, cfg in pairs(layer_cfg_table) do
    if cfg.galaxyid == galaxy_id and cfg.layer == layer then
      return cfg.id
    end
  end
  return 0
end

function M:_get_current_station_guid()
  if self._light_house_guid ~= nil and self._light_house_guid ~= 0 then
    return self._light_house_guid
  end
  local home_layer = self._home_layer or self:_get_home_layer_cfg_id()
  if home_layer == nil or home_layer == 0 then
    return nil
  end
  local station_list = CsStarSeaManagerV2Util.GetLayerStationList(home_layer)
  if is_null(station_list) then
    return nil
  end
  for _, st in ipairs(list_to_table(station_list)) do
    if st ~= nil and st.IsUnlocked == true then
      return st.Guid
    end
  end
  return nil
end

function M:_get_layer_cfg(layer_cfg_id)
  local layer_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaLayerCfg)) or {}
  for _, cfg in pairs(layer_cfg_table) do
    if cfg.id == layer_cfg_id then
      return cfg
    end
  end
  return nil
end

function M:_create_map_material()
  if is_null(self._img_map) then
    return nil
  end
  if is_null(self._map_mat_origin) then
    self._map_mat_origin = self._img_map.material
  end
  local old_mat = self._map_mat
  self._map_mat = Material(self._map_mat_origin)
  self._img_map.material = self._map_mat
  if not_null(old_mat) then
    UnityObject.Destroy(old_mat)
  end
  return self._map_mat
end

function M:_set_map_alpha(alpha)
  if is_null(self._img_map) then
    return
  end
  local color = self._img_map.color
  self._img_map.color = Color(color.r, color.g, color.b, alpha)
end

function M:_refresh_map_image(layer, immediate)
  local cfg = self:_get_layer_cfg(layer)
  if cfg == nil or not string.is_valid(cfg.sdftexture) then
    return
  end
  
  local function apply_sdf_texture()
    local mat = self:_create_map_material()
    if is_null(mat) then
      return
    end
    local sprite = UIUtil.get_sprite(cfg.sdftexture, self:get_load_proxy())
    if not is_null(sprite) then
      mat:SetTexture("_SDFTex", sprite.texture)
    end
  end
  
  if self._map_fade_tween ~= nil then
    self._map_fade_tween:Kill(false)
    self._map_fade_tween = nil
  end
  if immediate then
    apply_sdf_texture()
    self:_set_map_alpha(1)
    return
  end
  self._map_fade_tween = DOTween.Sequence()
  if self._map_hidden then
    apply_sdf_texture()
    self:_set_map_alpha(0)
  else
    self._map_fade_tween:Append(UIUtil.dt_to_anim(1, 0, MAP_FADE_TIME, function(value)
      self:_set_map_alpha(value)
    end, apply_sdf_texture))
  end
  self._map_fade_tween:Append(UIUtil.dt_to_anim(0, 1, MAP_FADE_TIME, function(value)
    self:_set_map_alpha(value)
  end, function()
    self._map_fade_tween = nil
  end))
end

function M:_init_slider()
  self._slider.minValue = MINUS_MAX_RATIO
  self._slider.maxValue = ADD_MAX_RATIO
  self:_set_slider_value(DEFAULT_RATIO)
end

function M:_set_slider_value(value)
  value = math.max(MINUS_MAX_RATIO, math.min(ADD_MAX_RATIO, value))
  if self._slider.SetValueWithoutNotify ~= nil then
    self._slider:SetValueWithoutNotify(value)
  else
    self._slider.value = value
  end
  self:_apply_map_scale(value)
end

function M:_apply_map_scale(value)
  self._map_scale = value
  self._trans_img_map:SetLocalScale(value, value, 1)
  self:_update_map_follow()
end

function M:_hide_map()
  if self._map_fade_tween ~= nil then
    self._map_fade_tween:Kill(false)
    self._map_fade_tween = nil
  end
  self._map_hidden = true
  if not is_null(self._trans_img_map) then
    self._trans_img_map:SetActive(false)
  end
  self._map_infos = {}
  self:_clear_map_icons()
  if not is_null(self._trans_player_point) then
    self._trans_player_point:SetActive(false)
  end
end

function M:_switch_layer(layer, immediate)
  self._cur_layer = layer
  self._season_btn_layer = layer
  self:_refresh_season_codex_red_point()
  if self._is_outside and self:_get_visited_station_id(layer) == nil then
    self:_hide_map()
    return
  end
  if not is_null(self._trans_img_map) then
    self._trans_img_map:SetActive(true)
  end
  self:_refresh_map_image(layer, immediate)
  self._map_hidden = false
  self:_collect_map_data(layer)
  self:_refresh_map_icons()
  local is_home = not self._is_outside and self._cur_layer == self._home_layer
  if not is_null(self._trans_player_point) then
    self._trans_player_point:SetActive(is_home)
  end
  self:_collect_player_pos()
  self:_update_map_follow()
  if not self._is_outside then
    self:_update_player_point_rotation()
  end
end

function M:_collect_map_data(layer)
  self._map_infos = {}
  if self._is_outside then
    self:_append_star_infos(CsStarSeaManagerV2Util.GetSeasonPreviewStarList(layer))
    self:_append_gate_infos(CsStarSeaManagerV2Util.GetSeasonPreviewGateList(layer))
    self:_append_station_infos(CsStarSeaManagerV2Util.GetSeasonPreviewStationList(layer), layer)
    return
  end
  self:_append_star_infos(CsStarSeaManagerV2Util.GetLayerActiveStarList(layer))
  self:_append_gate_infos(CsStarSeaManagerV2Util.GetLayerGateList(layer))
  self:_append_station_infos(CsStarSeaManagerV2Util.GetLayerStationList(layer), layer)
end

function M:_append_star_infos(cs_list)
  if is_null(cs_list) then
    return
  end
  for _, e in ipairs(list_to_table(cs_list)) do
    if e ~= nil then
      self._map_infos[#self._map_infos + 1] = {
        iconType = 1,
        iconPath = self:_get_island_icon(e),
        lockState = 2,
        position = {
          x = e.Position.x,
          z = e.Position.z
        },
        entityId = e.Guid
      }
    end
  end
end

function M:_append_gate_infos(cs_list)
  if is_null(cs_list) then
    return
  end
  local cfg = CsStarSeaManagerV2Util.Cfg
  for _, e in ipairs(list_to_table(cs_list)) do
    if e ~= nil and not _is_unrevealed_gate(e) then
      self._map_infos[#self._map_infos + 1] = {
        iconType = 3,
        iconPath = cfg.StarDoorIcon,
        lockState = e.IsLocked and 0 or 2,
        position = {
          x = e.Position.x,
          z = e.Position.z
        },
        entityId = e.Guid
      }
    end
  end
end

function M:_append_station_infos(cs_list, layer)
  if is_null(cs_list) then
    return
  end
  local cfg = CsStarSeaManagerV2Util.Cfg
  for _, e in ipairs(list_to_table(cs_list)) do
    if e ~= nil then
      self._map_infos[#self._map_infos + 1] = {
        iconType = 4,
        iconPath = cfg.LightHouseIcon,
        lockState = e.IsUnlocked and 2 or 0,
        position = {
          x = e.Position.x,
          z = e.Position.z
        },
        entityId = _station_entity_id(e),
        layerCfgId = layer
      }
    end
  end
end

function M:_get_island_icon(star)
  if star.IsVisited == false then
    return ISLAND_DEFAULT_ICON
  end
  local star_cfg = ExcelDataUtil.get_value(typeof(BStellarSeaStarCfg), star.StarId)
  if star_cfg ~= nil then
    local icon_cfg = ExcelDataUtil.get_value(typeof(BStarIslandIconCfg), star_cfg.radartrackingtypeid)
    if icon_cfg ~= nil and icon_cfg.icon ~= nil and icon_cfg.icon ~= "" then
      return icon_cfg.icon
    end
  end
  return ISLAND_DEFAULT_ICON
end

function M:_is_season_layer_available(cfg)
  if cfg.seasonid == nil or cfg.seasonid == 0 then
    return true
  end
  local station_list = CsStarSeaManagerV2Util.GetLayerStationList(cfg.id)
  return not is_null(station_list) and 0 < station_list.Count
end

function M:_collect_place_layer_cfgs()
  local layers = {}
  if self._is_outside then
    local layer_ids = CsStarSeaManagerV2Util.GetSeasonPreviewLayerIdList()
    if is_null(layer_ids) then
      return layers
    end
    for _, layer_cfg_id in ipairs(list_to_table(layer_ids)) do
      local cfg = self:_get_layer_cfg(layer_cfg_id)
      if cfg ~= nil then
        layers[#layers + 1] = cfg
      end
    end
    return layers
  end
  local layer_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaLayerCfg)) or {}
  for _, cfg in pairs(layer_cfg_table) do
    if cfg.stationshotcut ~= nil and cfg.stationshotcut ~= "" and self:_is_season_layer_available(cfg) then
      layers[#layers + 1] = cfg
    end
  end
  table.sort(layers, function(a, b)
    if a.galaxyid ~= b.galaxyid then
      return a.galaxyid < b.galaxyid
    end
    return a.layer < b.layer
  end)
  return layers
end

function M:_get_visited_station_id(layer_cfg_id)
  local station_list
  if self._is_outside then
    station_list = CsStarSeaManagerV2Util.GetSeasonPreviewStationList(layer_cfg_id)
  else
    station_list = CsStarSeaManagerV2Util.GetLayerStationList(layer_cfg_id)
  end
  if is_null(station_list) then
    return nil
  end
  for _, st in ipairs(list_to_table(station_list)) do
    if st ~= nil and st.IsUnlocked == true then
      return _station_entity_id(st)
    end
  end
  return nil
end

function M:_refresh_place_items()
  self._place_item_entries = self._place_item_entries or {}
  for _, item in ipairs(self._place_item_entries) do
    if not is_null(item._tog) then
      item._tog:SetIsOnWithoutNotify(false)
    end
    if item.set_active ~= nil then
      item:set_active(false)
    end
  end
  self._obj_place_item:SetActive(false)
  local parent = not is_null(self._trans_place_item_parent) and self._trans_place_item_parent or self._obj_place_item.transform.parent
  local idx = 0
  for _, cfg in ipairs(self:_collect_place_layer_cfgs()) do
    local visited_station_id = self:_get_visited_station_id(cfg.id)
    local is_unlocked = visited_station_id ~= nil
    idx = idx + 1
    local item = self._place_item_entries[idx]
    if item == nil then
      local go = GameObject.Instantiate(self._obj_place_item, parent)
      item = self:add_panel("UI/StarExplore/StarExploreRiverStationButton", go)
      item:set_toggle_callback(function(is_on, data, station_item)
        self:_on_river_station_toggle_changed(is_on, data, station_item)
      end)
      self._place_item_entries[idx] = item
    end
    item.trans:SetParent(parent, false)
    item.trans:SetAsLastSibling()
    item:set_active(true)
    if not is_null(item._tog) then
      item._tog:SetIsOnWithoutNotify(false)
    end
    item:set_data({
      iconType = 4,
      galaxyid = cfg.galaxyid,
      layer = cfg.layer,
      layerCfgId = cfg.id,
      name = cfg.name,
      mapfilepath = cfg.mapfilepath,
      lockState = is_unlocked and 2 or 0,
      isUnlocked = is_unlocked,
      entityId = visited_station_id,
      currentStationGuid = self._current_station_guid,
      isOutsideStarSea = self._is_outside,
      isSeasonLayer = self:_is_season_layer(cfg.id)
    })
  end
  self._place_item_count = idx
end

function M:_clear_map_icons()
  for _, go in ipairs(self._map_icon_entries or {}) do
    if not is_null(go) then
      UIUtil.destroy_go(go)
    end
  end
  self._map_icon_entries = {}
  if not is_null(self._obj_island_icon) then
    self._obj_island_icon:SetActive(false)
  end
  if not is_null(self._obj_station) then
    self._obj_station:SetActive(false)
  end
end

function M:_refresh_map_icons()
  self:_clear_map_icons()
  for i, info in ipairs(self._map_infos) do
    local is_station = info.iconType == 4
    local template = is_station and self._obj_station or self._obj_island_icon
    local parent = not is_null(self._trans_img_map) and self._trans_img_map or template.transform.parent
    local go = GameObject.Instantiate(template, parent)
    self._map_icon_entries[i] = go
    go:SetActive(true)
    local img = go.transform:GetComponentInChildren(typeof(Image))
    UIUtil.set_image(img, info.iconPath, self:get_load_proxy())
    local lock_scg = UIUtil.find_cmpt(go, "ui_lock_change_group", typeof(UIStateChangeGroup))
    if not is_null(lock_scg) then
      lock_scg:SetState(info.lockState or 2)
    end
    if is_station then
      local toggle = go.transform:GetComponentInChildren(typeof(Toggle))
      if not is_null(toggle) then
        local click_toggle = toggle
        local click_info = info
        self:bind_callback(toggle, function(is_on)
          if is_on then
            self:_set_all_station_icon_toggle_off(click_toggle)
          end
          self:_toggle_river_station(click_info, is_on)
        end)
      end
    end
    local pos = info.position
    if pos ~= nil then
      go.transform:SetAnchoredPos3D(pos.x * MAP_POS_RATIO, pos.z * MAP_POS_RATIO, 0)
    end
  end
end

function M:_collect_player_pos()
  self._player_pos = nil
  if self._is_outside then
    return
  end
  local cur_car = CsStarSeaManagerV2Util.CurCar
  if is_null(cur_car) or is_null(cur_car.Owner) or not cur_car.Owner.IsValid then
    return
  end
  self._player_pos = cur_car.Owner:GetPosition()
end

function M:_update_map_follow()
  if is_null(self._trans_img_map) then
    return
  end
  if is_null(self._player_pos) then
    if self._is_outside then
      self._trans_img_map:SetLocalPosition(0, 0, 0)
    end
    return
  end
  local scale = self._map_scale or DEFAULT_RATIO
  local offset_x = -self._player_pos.x * scale * MAP_POS_RATIO
  local offset_y = -self._player_pos.z * scale * MAP_POS_RATIO
  self._trans_img_map:SetLocalPosition(offset_x, offset_y, 0)
end

function M:_update_player_point_rotation()
  local _, _, _, y = GameplayUtilities_StarSea.GetCarPositionAndRotation()
  if not is_null(self._trans_player_point) then
    self._trans_player_point:SetRotation(0, 0, -y)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_season_codex_red_point()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnCodexSeasonNumRewardUpdate, pack(self, M._refresh_season_codex_red_point))
  self:add_evt_listener(EventID.CodexDataUpdate, pack(self, M._on_codex_data_update))
end

function M:_on_codex_data_update()
  self:_refresh_season_codex_red_point()
end

function M:_is_season_layer(layer_cfg_id)
  if layer_cfg_id == nil or layer_cfg_id == 0 then
    return false
  end
  local layer_ids = CsStarSeaManagerV2Util.GetSeasonPreviewLayerIdList()
  if is_null(layer_ids) then
    return false
  end
  for _, id in ipairs(list_to_table(layer_ids)) do
    if id == layer_cfg_id then
      return true
    end
  end
  return false
end

function M:_refresh_season_codex_red_point()
  local has_season = theme_season_module:get_cur_season_id() ~= 0 and self:_is_season_layer(self._season_btn_layer)
  if not_null(self._trans_btn_season) then
    UIUtil.set_active(self._trans_btn_season, has_season)
  elseif not_null(self._btn_season_codex) then
    UIUtil.set_active(self._btn_season_codex, has_season)
  end
  if is_null(self._season_codex_rpc) then
    return
  end
  self._season_codex_rpc:ShowRedPoint(theme_season_module:get_season_codex_red_point_type())
end

function M:_on_btn_season_codex_click()
  theme_season_module:open_season_codex_page()
end

function M:update(delta_time)
  if self._is_outside or self._cur_layer ~= self._home_layer then
    return
  end
  self:_collect_player_pos()
  self:_update_map_follow()
  self:_update_player_point_rotation()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  if self._map_fade_tween ~= nil then
    self._map_fade_tween:Kill(false)
    self._map_fade_tween = nil
  end
  base.on_close(self)
end

function M:on_destroy()
  if not_null(self._map_mat) then
    if not_null(self._img_map) and not_null(self._map_mat_origin) then
      self._img_map.material = self._map_mat_origin
    end
    UnityObject.Destroy(self._map_mat)
    self._map_mat = nil
    self._map_mat_origin = nil
  end
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._slider, pack(self, M._on_slider_value_changed))
  self:bind_callback(self._btn_slider_add, pack(self, M._on_btn_slider_add_click))
  self:bind_callback(self._btn_slider_minus, pack(self, M._on_btn_slider_minus_click))
  if not_null(self._btn_season_codex) then
    self:bind_callback(self._btn_season_codex, pack(self, M._on_btn_season_codex_click))
  end
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_slider_value_changed(value)
  self:_apply_map_scale(value)
end

function M:_on_btn_slider_add_click()
  self._slider.value = self._slider.value + STEP_RATIO
end

function M:_on_btn_slider_minus_click()
  self._slider.value = self._slider.value - STEP_RATIO
end

function M:_toggle_river_station(info, is_on)
  local target, best = nil, 0
  for i = 1, self._place_item_count or 0 do
    local item = self._place_item_entries[i]
    local level = _station_match_level(item ~= nil and item._data or nil, info)
    if best < level then
      target, best = item, level
      if level == 2 then
        break
      end
    end
  end
  if target == nil or is_null(target._tog) then
    return
  end
  if target._tog.isOn == is_on then
    self:_sync_station_icon_toggle(is_on and target._data or nil)
  else
    target._tog.isOn = is_on
  end
end

function M:_set_all_station_icon_toggle_off(except_toggle)
  for i, info in ipairs(self._map_infos or {}) do
    if info.iconType == 4 then
      local go = self._map_icon_entries and self._map_icon_entries[i]
      if not is_null(go) then
        local toggle = go.transform:GetComponentInChildren(typeof(Toggle))
        if not is_null(toggle) and toggle ~= except_toggle then
          toggle:SetIsOnWithoutNotify(false)
        end
      end
    end
  end
end

function M:_find_station_icon_index(data)
  if data == nil then
    return nil
  end
  local target, best = nil, 0
  for i, info in ipairs(self._map_infos or {}) do
    local level = _station_match_level(data, info)
    if best < level then
      target, best = i, level
      if level == 2 then
        break
      end
    end
  end
  return target
end

function M:_sync_station_icon_toggle(data)
  local target_index = self:_find_station_icon_index(data)
  for i, info in ipairs(self._map_infos or {}) do
    if info.iconType == 4 then
      local go = self._map_icon_entries and self._map_icon_entries[i]
      if not is_null(go) then
        local toggle = go.transform:GetComponentInChildren(typeof(Toggle))
        if not is_null(toggle) then
          toggle:SetIsOnWithoutNotify(i == target_index)
        end
      end
    end
  end
end

function M:_on_river_station_toggle_changed(is_on, data, station_item)
  if is_on then
    local is_unlocked = data == nil or data.isUnlocked ~= false
    if is_unlocked then
      if not is_null(self._trans_img_map) then
        self._trans_img_map:SetActive(true)
      end
      if not is_null(self._trans_player_point) then
        self._trans_player_point:SetActive(not self._is_outside and self._cur_layer == self._home_layer)
      end
      if data ~= nil and data.layerCfgId ~= nil and (data.layerCfgId ~= self._cur_layer or self._map_hidden) then
        self:_switch_layer(data.layerCfgId)
      end
      self:_sync_station_icon_toggle(data)
    else
      self:_hide_map()
      self:_sync_station_icon_toggle(nil)
      self._season_btn_layer = data ~= nil and data.layerCfgId or 0
      self:_refresh_season_codex_red_point()
    end
    if self._teleportation_detail_panel ~= nil then
      self._teleportation_detail_panel:set_data(data)
      self._teleportation_detail_panel:set_active(true)
    elseif not is_null(self._trans_ani_right) then
      self._trans_ani_right:SetActive(true)
    end
  else
    local has_any_on = false
    for i = 1, self._place_item_count or 0 do
      local item = self._place_item_entries[i]
      if item ~= nil and not is_null(item._tog) and item._tog.isOn then
        has_any_on = true
        break
      end
    end
    if has_any_on then
      return
    end
    self:_sync_station_icon_toggle(nil)
    if self._teleportation_detail_panel ~= nil then
      self._teleportation_detail_panel:set_active(false)
    elseif not is_null(self._trans_ani_right) then
      self._trans_ani_right:SetActive(false)
    end
  end
end

return M
