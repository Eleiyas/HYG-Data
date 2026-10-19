local M = G.Class("PlantPlotSettingPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
  self._tog_advanced_fruit.isOn = CsCropStatModuleUtil.IsAdvancedFruitHarvestTipOn()
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_callbacks()
  self:bind_callback(self._tog_advanced_fruit, function(is_on)
    CsCropStatModuleUtil.SetAdvancedFruitHarvestTipState(is_on)
  end)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnAdvancedFruitHarvestTipStateChanged, function(is_on)
    if self._tog_advanced_fruit.isOn ~= is_on then
      self._tog_advanced_fruit.isOn = is_on
    end
  end)
end

return M
