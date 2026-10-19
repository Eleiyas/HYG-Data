local M = G.Class("GeLianMarketTopBarPanel", G.UIPanel)
local base = G.UIPanel
local market_time_util = require("UI/GeLianMarket/GeLianMarketTimeUtil")
local REFRESH_INTERVAL = 60

function M:init()
  base.init(self)
  self._help_callback = nil
  self._coin_view = nil
  self._cycle_timer = nil
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data() or {}
  self._help_callback = context.help_callback
  self._coin_view = self:add_panel("UI/CommonUI/CommonCoinItemView", self._trans_coin_item, {
    coin_id = back_bag_module.coin_type.gold,
    auto_update = true,
    show_detail = true
  })
  self._coin_view:set_show_add(false)
  self:bind_callback(self._btn_help, pack(self, M.on_help_requested))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_cycle_text()
  self:_start_cycle_timer()
end

function M:on_disable()
  self:_stop_cycle_timer()
  base.on_disable(self)
end

function M:on_destroy()
  self:_stop_cycle_timer()
  base.on_destroy(self)
end

function M:_refresh_cycle_text()
  UIUtil.set_text_by_id(self._txt_cycle, "Market_NextRotationTime", market_time_util.get_rotation_left_time())
end

function M:_start_cycle_timer()
  self:_stop_cycle_timer()
  self._cycle_timer = CsCoroutineManagerUtil.Invoke(REFRESH_INTERVAL, function()
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

function M:on_help_requested()
  if self._help_callback then
    self._help_callback()
  end
end

return M
