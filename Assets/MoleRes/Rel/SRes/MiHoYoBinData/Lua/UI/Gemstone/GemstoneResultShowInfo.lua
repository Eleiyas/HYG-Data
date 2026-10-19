local M = G.Class("GemstoneResultShowInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Gemstone/GemstoneResultShowInfo"
  self.config.type = EUIType.Dialog
  self.config.order_in_layer = 99
  self._is_close = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  self._is_close = false
  base.on_enable(self)
  self:_refresh()
  self.trans:SetAsLastSibling()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, function()
    self:_close_self()
  end)
end

function M:_add_ui_listener()
  if self._Bg_FullScreenMask then
    self:bind_close_btn(self._Bg_FullScreenMask)
  end
end

function M:_refresh()
  local reward_item_config_id = CsNPCPersonaGameModuleUtil.GetLastGemDisplayRewardItemConfigId()
  local reward_value = CsNPCPersonaGameModuleUtil.GetLastGemRewardValue()
  local item_cfg
  local has_delayed_reward = CsNPCPersonaGameModuleUtil.HasLastGemDelayedReward()
  if 0 < reward_item_config_id then
    item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), reward_item_config_id)
  end
  if not is_null(item_cfg) then
    UIUtil.set_image(self._img_icon_dynamic, item_cfg.icon, self:get_load_proxy())
    UIUtil.set_text(self._txt_name_dynamic, item_cfg.name)
  else
    UIUtil.set_text(self._txt_name_dynamic, "")
  end
  if self._state_group_result then
    self._state_group_result:SetState(reward_value == 1 and 1 or 0)
  end
end

function M:close_self()
  base.close_self(self)
  if self._is_close then
    return
  end
  self._is_close = true
  EventCenter.Broadcast(EventID.Performance.OnGemstoneResultShowInfoEnd, 0)
end

return M
