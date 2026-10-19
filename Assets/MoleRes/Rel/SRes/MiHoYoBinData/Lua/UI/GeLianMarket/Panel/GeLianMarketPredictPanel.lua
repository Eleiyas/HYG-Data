local M = G.Class("GeLianMarketPredictPanel", G.UIPanel)
local base = G.UIPanel
local view_model = gelian_market_module.view_model
local time_util = require("UI/GeLianMarket/GeLianMarketTimeUtil")
local crop_item_cls = "UI/GeLianMarket/Panel/GeLianMarketPredictCropItem"
local CYCLE_REFRESH_INTERVAL = 60
local PredictUIState = {
  HasPrediction = 0,
  NoPrediction = 1,
  Locked = 2
}

function M:init()
  base.init(self)
  self._view_data = nil
  self._page_service = nil
  self._rank_items = {}
  self._cycle_timer = nil
  self._unlock_task_tag_id = nil
  self._has_resolved_unlock_task_tag = false
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._page_service = context and context.page_service or nil
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_cycle_text()
  self:_start_cycle_timer()
  self:_play_slider_anims()
end

function M:on_disable()
  self:_stop_cycle_timer()
  base.on_disable(self)
end

function M:on_destroy()
  self:_stop_cycle_timer()
  self._page_service = nil
  self._view_data = nil
  self._rank_items = {}
  self._unlock_task_tag_id = nil
  self._has_resolved_unlock_task_tag = false
  base.on_destroy(self)
end

function M:request_enter_sell(payload)
  if self._page_service ~= nil then
    self._page_service:enter_sell(payload)
  end
end

function M:render(view_data)
  self._view_data = view_data
  local is_locked = view_data ~= nil and view_data.state == view_model.PredictState.Locked
  local is_collecting = view_data ~= nil and view_data.state == view_model.PredictState.Collecting
  local items = is_collecting and view_data.items or nil
  local has_items = items ~= nil and 0 < #items
  local predict_state = PredictUIState.NoPrediction
  if is_locked then
    predict_state = PredictUIState.Locked
    self:_refresh_lock_text()
  elseif has_items then
    predict_state = PredictUIState.HasPrediction
  end
  self._state_group_predict:SetState(predict_state)
  if has_items then
    self:_refresh_rank_list(items)
  end
  self:_refresh_prediction_text(view_data and view_data.prediction_target or nil)
  self:_refresh_cycle_text()
  if self.is_active then
    self:_play_slider_anims()
  end
end

function M:_refresh_lock_text()
  UIUtil.set_text_by_id(self._txt_lock, "Market_Predict_Unlock_Tip")
end

function M:_refresh_prediction_text(target)
  if target == nil then
    return
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), target.display_config_id)
  local crop_name = item_cfg and item_cfg.name or ""
  local mature_days = self:_get_crop_growth_days(target.tag)
  UIUtil.set_text_by_id(self._txt_predict_content, "Market_Predict_Content", crop_name, mature_days)
end

function M:_get_crop_growth_days(crop_tag)
  local plant_cfg_table = ExcelDataUtil.get_table(typeof(BCropPlantCfg)) or {}
  for _, plant_cfg in pairs(plant_cfg_table) do
    if plant_cfg.name == crop_tag then
      return plant_cfg.stageseedlingidlistLength or 0
    end
  end
  return 0
end

function M:_refresh_rank_list(items)
  for i = #self._rank_items + 1, #items do
    local trans = self._list_item_binder_rank:AddItem(0, true)
    if is_null(trans) then
      return
    end
    self._rank_items[i] = self:add_panel(crop_item_cls, trans)
  end
  for i = 1, #self._rank_items do
    self._rank_items[i]:render(items[i])
  end
end

function M:_play_slider_anims()
  local view_data = self._view_data
  if view_data == nil or view_data.state ~= view_model.PredictState.Collecting then
    return
  end
  local items = view_data.items or {}
  for i = 1, #self._rank_items do
    local item = items[i]
    if item ~= nil then
      local anim = view_model.take_prediction_anim(item.tag)
      if anim ~= nil then
        self._rank_items[i]:play_slider_anim(anim.from / 100, anim.to / 100)
      end
    end
  end
end

function M:_refresh_cycle_text()
  if self._view_data == nil or self._view_data.state ~= view_model.PredictState.Collecting then
    return
  end
  UIUtil.set_active(self._txt_cycle, true)
  UIUtil.set_text_by_id(self._txt_cycle, "CropTrading_PriceChange_Tips2", time_util.get_next_price_refresh_left_time())
end

function M:_start_cycle_timer()
  self:_stop_cycle_timer()
  self._cycle_timer = CsCoroutineManagerUtil.Invoke(CYCLE_REFRESH_INTERVAL, function()
    if self.is_active then
      self:_refresh_cycle_text()
      self:_start_cycle_timer()
    end
  end)
end

function M:_stop_cycle_timer()
  if self._cycle_timer ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._cycle_timer)
    self._cycle_timer = nil
  end
end

return M
