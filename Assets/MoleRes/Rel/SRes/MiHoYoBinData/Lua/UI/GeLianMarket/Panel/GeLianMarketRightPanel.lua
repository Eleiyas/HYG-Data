local M = G.Class("GeLianMarketRightPanel", "UI/GeLianMarket/Panel/GeLianMarketContainerPanel")
local base = G.GeLianMarketContainerPanel
local market_page_service_cls = require("UI/GeLianMarket/GeLianMarketPageService")
local PanelKey = {
  Predict = "predict",
  CropPrice = "crop_price",
  ComparePrice = "compare_price",
  LeaveMessage = "leave_message"
}
local panel_configs = {
  [PanelKey.Predict] = {
    class_name = "UI/GeLianMarket/Panel/GeLianMarketPredictPanel",
    parent_field = "_trans_predict_panel",
    data_field = "prediction"
  },
  [PanelKey.CropPrice] = {
    class_name = "UI/GeLianMarket/Panel/GeLianMarketCropPricePanel",
    parent_field = "_trans_crop_price_panel",
    data_field = "market",
    panel_mode = "market"
  },
  [PanelKey.ComparePrice] = {
    class_name = "UI/GeLianMarket/Panel/GeLianMarketCropPricePanel",
    parent_field = "_trans_compare_price_panel",
    data_field = "compare",
    panel_mode = "compare"
  },
  [PanelKey.LeaveMessage] = {
    class_name = "UI/GeLianMarket/Panel/GeLianMarketLeaveMessagePanel",
    parent_field = "_trans_message_panel",
    data_field = "leave_message"
  }
}

function M:init()
  base.init(self)
  self._view_data = nil
  self._panels = {}
  self._loading_panels = {}
  self._shown_panel = nil
  self._pending_panel_key = nil
  self._pending_panel_version = 0
  self._is_destroyed = false
  self._is_compare_expanded = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:provide_service_port(market_page_service_cls.Port.RightArea, {
    show_market_overview = pack(self, M.show_market_overview),
    show_prediction = pack(self, M.show_prediction),
    enter_sell = pack(self, M.enter_sell),
    show_friend_price = pack(self, M.show_friend_price),
    show_return_rank = pack(self, M.show_return_rank),
    show_leave_message = pack(self, M.show_leave_message),
    refresh = pack(self, M.refresh)
  })
end

function M:on_destroy()
  self._is_destroyed = true
  self._view_data = nil
  self._panels = {}
  self._loading_panels = {}
  self._shown_panel = nil
  self._pending_panel_key = nil
  self._is_compare_expanded = false
  base.on_destroy(self)
end

function M:show_market_overview(payload)
  self:_begin_show_request()
  self._is_compare_expanded = false
  self._tog_fold:SetIsOnWithoutNotify(false)
  UIUtil.set_active(self._trans_tabs, self._view_data ~= nil and self._view_data.is_self_page == true)
  self._tog_market:SetIsOnWithoutNotify(true)
  self._pending_panel_key = PanelKey.CropPrice
  local request_version = self._pending_panel_version
  self:_ensure_panel(PanelKey.CropPrice, function(panel)
    if request_version ~= self._pending_panel_version or self._pending_panel_key ~= PanelKey.CropPrice then
      return
    end
    self:_show_loaded_panel(PanelKey.CropPrice, panel)
    UIUtil.set_active(self._trans_compare_price_panel, false)
  end)
end

function M:show_prediction(payload)
  self:_clear_prediction_red_point()
  self:_request_show_panel(PanelKey.Predict)
  UIUtil.set_active(self._trans_tabs, true)
end

function M:enter_sell(payload)
  self._pending_panel_version = self._pending_panel_version + 1
  UIUtil.set_active(self._trans_tabs, false)
  if self._tog_fold.isOn then
    self._tog_fold.isOn = false
  end
end

function M:show_friend_price(payload)
  self:_hide_all_content()
end

function M:show_return_rank(payload)
  self:_hide_all_content()
end

function M:show_leave_message(payload)
  self:_hide_all_content()
  self:_request_show_panel(PanelKey.LeaveMessage)
end

function M:refresh(view_data)
  self._view_data = view_data
  self:_refresh_prediction_red_point()
  for panel_key, panel in pairs(self._panels) do
    if panel_key ~= PanelKey.ComparePrice or not self._is_compare_expanded then
      self:_render_panel(panel_key, panel)
    end
  end
  if self._pending_panel_key == PanelKey.CropPrice then
    self:_refresh_compare_panel()
  end
end

function M:_add_ui_listener()
  self:bind_callback(self._tog_market, pack(self, M._on_tog_market))
  self:bind_callback(self._tog_predict, pack(self, M._on_tog_predict))
  self:bind_callback(self._tog_fold, pack(self, M._on_tog_fold))
end

function M:_on_tog_market(is_on)
  if is_on then
    self:show_market_overview()
  end
end

function M:_on_tog_predict(is_on)
  if is_on then
    self:_clear_prediction_red_point()
    self._page_service:enter_prediction()
  end
end

function M:_on_tog_fold(is_on)
  self._is_compare_expanded = is_on == true
  self:_refresh_compare_panel()
end

function M:_refresh_compare_panel()
  local should_show = self._pending_panel_key == PanelKey.CropPrice and self._is_compare_expanded
  UIUtil.set_active(self._trans_compare_price_panel, should_show)
  if not should_show then
    local compare_panel = self._panels[PanelKey.ComparePrice]
    if compare_panel ~= nil then
      compare_panel:set_active(false)
    end
    return
  end
  local request_version = self._pending_panel_version
  self:_ensure_panel(PanelKey.ComparePrice, function(compare_panel)
    if request_version == self._pending_panel_version and self._pending_panel_key == PanelKey.CropPrice and self._is_compare_expanded then
      self:_render_panel(PanelKey.ComparePrice, compare_panel)
      compare_panel:set_active(true)
    end
  end)
end

function M:_refresh_prediction_red_point()
  if not CsOpenStateModuleUtil.GetConditionIsUnlock(161) then
    self._red_point_predict:ShowRedPoint(RedPointType.None)
    return
  end
  if self._pending_panel_key == PanelKey.Predict and CsGeLianMarketModuleUtil.IsNewData then
    CsGeLianMarketModuleUtil.IsNewData = false
  end
  self._red_point_predict:ShowRedPoint(CsGeLianMarketModuleUtil.IsNewData and RedPointType.NewRp or RedPointType.None)
end

function M:_clear_prediction_red_point()
  CsGeLianMarketModuleUtil.IsNewData = false
  self:_refresh_prediction_red_point()
end

function M:_begin_show_request()
  self._pending_panel_version = self._pending_panel_version + 1
  self:_hide_all_content()
end

function M:_request_show_panel(panel_key)
  self:_begin_show_request()
  self._pending_panel_key = panel_key
  local request_version = self._pending_panel_version
  self:_ensure_panel(panel_key, function(panel)
    if request_version == self._pending_panel_version and self._pending_panel_key == panel_key then
      self:_show_loaded_panel(panel_key, panel)
    end
  end)
end

function M:_hide_all_content()
  self._pending_panel_key = nil
  UIUtil.set_active(self._trans_predict_panel, false)
  UIUtil.set_active(self._trans_crop_price_panel, false)
  UIUtil.set_active(self._trans_compare_price_panel, false)
  UIUtil.set_active(self._trans_message_panel, false)
  UIUtil.set_active(self._trans_tabs, false)
  if self._shown_panel ~= nil then
    self._shown_panel:set_active(false)
    self._shown_panel = nil
  end
end

function M:_show_loaded_panel(panel_key, panel)
  if self._shown_panel ~= nil and self._shown_panel ~= panel then
    self._shown_panel:set_active(false)
  end
  self:_render_panel(panel_key, panel)
  panel:set_active(true)
  self._shown_panel = panel
end

function M:_ensure_panel(panel_key, complete)
  local panel = self._panels[panel_key]
  if panel ~= nil then
    complete(panel)
    return
  end
  local config = panel_configs[panel_key]
  if config.parent_field == nil then
    self:_ensure_prefab_panel(panel_key, complete)
    return
  end
  local panel_trans = self[config.parent_field]
  if is_null(panel_trans) then
    return
  end
  local context = self:get_extra_data() or {}
  panel = self:add_panel(config.class_name, panel_trans, {
    page_service = context.page_service,
    market_panel_mode = config.panel_mode
  })
  self._panels[panel_key] = panel
  self:_render_panel(panel_key, panel)
  complete(panel)
end

function M:_ensure_prefab_panel(panel_key, complete)
  local callbacks = self._loading_panels[panel_key]
  if callbacks ~= nil then
    table.insert(callbacks, complete)
    return
  end
  local config = panel_configs[panel_key]
  callbacks = {complete}
  self._loading_panels[panel_key] = callbacks
  self:add_panel_async(config.class_name, self:get_extra_data(), self._trans_content, function(loaded_panel)
    if self._is_destroyed then
      return
    end
    local pending_callbacks = self._loading_panels[panel_key] or {}
    self._loading_panels[panel_key] = nil
    self._panels[panel_key] = loaded_panel
    loaded_panel:set_active(false)
    self:_render_panel(panel_key, loaded_panel)
    for i = 1, #pending_callbacks do
      pending_callbacks[i](loaded_panel)
    end
  end)
end

function M:_render_panel(panel_key, panel)
  local data_field = panel_configs[panel_key].data_field
  if data_field ~= nil then
    local owner_name
    if panel_key == PanelKey.CropPrice then
      owner_name = self._view_data and self._view_data.market_owner_name or ""
    elseif panel_key == PanelKey.ComparePrice then
      owner_name = self._view_data and self._view_data.self_market_owner_name or ""
    end
    panel:render(self._view_data and self._view_data[data_field] or nil, owner_name, self._view_data ~= nil and self._view_data.is_self_page == false, panel_configs[panel_key].panel_mode)
  end
end

return M
