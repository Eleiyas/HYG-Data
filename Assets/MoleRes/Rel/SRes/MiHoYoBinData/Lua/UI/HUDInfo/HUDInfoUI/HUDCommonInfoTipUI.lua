local M = G.Class("HUDCommonInfoTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local show_time = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Tips/CommonInfoTip_Oneline"
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  if not (data ~= nil and string.is_valid(data.icon)) or not string.is_valid(data.text) then
    self:close_self()
    return
  end
  UIUtil.set_image(self._img_icon_dynamic, data.icon, self:get_load_proxy())
  UIUtil.set_text(self._txt_info_dynamic, data.text)
  self:start_close_timer(show_time)
end

function M:on_disable()
  base.on_disable(self)
  self:set_extra_data(nil)
end

return M
