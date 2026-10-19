local M = G.Class("GeLianMarketPredictCropItem", G.UIBase)
local base = G.UIBase

local function get_fruit_plant_second_id(crop_tag)
  if not string.is_valid(crop_tag) then
    return nil
  end
  local plant_cfg_table = ExcelDataUtil.get_table(typeof(BCropPlantCfg)) or {}
  for _, plant_cfg in pairs(plant_cfg_table) do
    if plant_cfg.name == crop_tag then
      if plant_cfg.fruitplantidlistLength >= 2 then
        return plant_cfg:fruitplantidlist(1)
      end
      return nil
    end
  end
  return nil
end

function M:init()
  base.init(self)
  self._view_data = nil
  self._slider_tween = nil
end

function M:on_destroy()
  self:_kill_slider_tween()
  self._view_data = nil
  base.on_destroy(self)
end

function M:render(view_data)
  self._view_data = view_data
  if view_data == nil then
    self:_kill_slider_tween()
    self:set_active(false)
    return
  end
  self:set_active(true)
  local display_id = get_fruit_plant_second_id(view_data.tag) or view_data.display_config_id
  item_module:set_item_icon(self._img_food, display_id, nil, nil, self:get_load_proxy())
  item_module:set_item_name(self._txt_name, display_id)
  self._slider_percent.value = view_data.percent / 100
  UIUtil.set_text(self._txt_percent, TextMapFormatUtil.FormatPercent(view_data.percent / 100, 0))
  self:_set_rank_state(view_data)
end

function M:play_slider_anim(from_value, to_value)
  self:_kill_slider_tween()
  self._slider_percent.value = from_value
  self._slider_tween = UIUtil.dt_to_anim(from_value, to_value, 0.5, function(value)
    if not is_null(self._slider_percent) then
      self._slider_percent.value = value
    end
  end)
end

function M:_kill_slider_tween()
  if self._slider_tween ~= nil then
    self._slider_tween:Kill()
    self._slider_tween = nil
  end
end

function M:_set_rank_state(view_data)
  local rank_state = view_data.rank - 1
  if rank_state < 0 then
    rank_state = 0
  elseif 2 < rank_state then
    rank_state = 2
  end
  self._state_group_rank:SetState(rank_state)
end

return M
