local M = G.Class("HUDCookBuffTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local show_time = 3.0
local ICON_SHOW_TYPE_DEBUFF = 2
local STATE_BUFF = 0
local STATE_DEBUFF = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Cooking/CookBuffTips"
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data()
  if extra_data == nil then
    self:close_self()
    return
  end
  local buff_cfg = ExcelDataUtil.get_value(typeof(BBuffCfg), extra_data.buffId)
  if buff_cfg == nil then
    self:close_self()
    return
  end
  local item_cfg = item_module:get_cfg_by_id(extra_data.itemId)
  if item_cfg == nil then
    self:close_self()
    return
  end
  UIUtil.set_text_by_id(self._txt, "Buff_Effect_Gained", buff_cfg.buffname)
  UIUtil.set_image(self._img_icon, item_cfg.icon, self:get_load_proxy())
  local state = buff_cfg.iconshowtype == ICON_SHOW_TYPE_DEBUFF and STATE_DEBUFF or STATE_BUFF
  self._state_group:SetState(state)
  self.is_unlock = true
  self:start_close_timer(show_time)
end

function M:on_disable()
  base.on_disable(self)
  self:set_extra_data(nil)
end

return M
