local M = G.Class("StarExploreRiverStationButton", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self._tog.isOn = false
  self:bind_callback(self._tog, function(is_on)
    if self._on_toggle_changed ~= nil then
      self._on_toggle_changed(is_on, self._data, self)
    end
    self:_refresh_state()
  end)
  self:_refresh_state()
  self._tog.isOn = false
end

function M:_refresh_state()
  local data = self._data or {}
  local cur_galaxy_id = CsStarSeaManagerV2Util.GetGalaxyId()
  local cur_layer = CsStarSeaManagerV2Util.GetLayerId()
  local is_current_layer = data.galaxyid == cur_galaxy_id and data.layer == cur_layer
  self._state_group_position:SetState(is_current_layer and 0 or 1)
  if data.lockState == 2 then
    self._state_group_lock:SetState(0)
  else
    self._state_group_lock:SetState(1)
  end
end

function M:set_data(data)
  self._data = data
  local galaxy_id = data and data.galaxyid or CsStarSeaManagerV2Util.GetGalaxyId()
  local layer = data and data.layer or CsStarSeaManagerV2Util.GetLayerId()
  local place_name = ""
  local station_shotcut = ""
  local layer_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaLayerCfg)) or {}
  for _, cfg in pairs(layer_cfg_table) do
    if cfg.galaxyid == galaxy_id and cfg.layer == layer then
      place_name = cfg.name or ""
      station_shotcut = cfg.stationshotcut or ""
      break
    end
  end
  UIUtil.set_text(self._txt_placename, place_name)
  UIUtil.set_image(self._img_unlock, station_shotcut, self:get_load_proxy())
  self:_refresh_state()
end

function M:set_toggle_callback(callback)
  self._on_toggle_changed = callback
end

return M
