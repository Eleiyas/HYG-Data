local M = G.Class("StarExpressTipsDialog", G.UIWindow)
local base = G.UIWindow
local auto_close_duration = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExpress/StarExpressTipsDialog"
  self.config.type = EUIType.Tip
  self.config.input_penetrate = true
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  local state = self._extra_data ~= nil and self._extra_data.state or star_express_module.tips_dialog_state.start_deliver
  if state == star_express_module.tips_dialog_state.all_delivered then
    local rider_level = star_express_module:get_rider_level()
    local rider_level_cfg = star_express_module:get_rider_level_cfg(rider_level)
    local max_order_num = rider_level_cfg ~= nil and (rider_level_cfg.maxordernum or 0) or 0
    local daily_accept_count = CsStarExpressModuleUtil.DailyAcceptCount or 0
    if 0 < max_order_num - daily_accept_count then
      state = star_express_module.tips_dialog_state.delivered
    end
  end
  self._ui_state_group:SetState(state)
  CoolDownManagerIns:register(self, auto_close_duration, function()
    self:_close()
  end)
  UIUtil.set_text_by_id(self._txt_title1, "StarExpress_Hud_StartDeliver")
  UIUtil.set_text_by_id(self._txt_title2, "StarExpress_Hud_Delivered")
  UIUtil.set_text_by_id(self._txt_title3, "StarExpress_Hud_AllDelivered")
end

function M:on_disable()
  base.on_disable(self)
  CoolDownManagerIns:unregister(self)
  star_express_module:check_open_exp_up_tips_dialog()
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_close()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

return M
