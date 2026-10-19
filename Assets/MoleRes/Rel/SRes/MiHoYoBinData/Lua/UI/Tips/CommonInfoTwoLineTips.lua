local M = G.Class("CommonInfoTwoLineTips", G.UIWindow)
local base = G.UIWindow
local auto_close_delay_seconds = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Tips/CommonInfoTip_Twoline"
  self.config.type = EUIType.Info
end

function M:on_create()
  base.on_create(self)
  self._remaining_time = 0
end

function M:on_open()
  base.on_open(self)
  self._remaining_time = auto_close_delay_seconds
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:update(delta_time)
  base.update(self, delta_time)
  self._remaining_time = self._remaining_time - delta_time
  if self._remaining_time <= 0 then
    self._remaining_time = 0
    self:close_self()
  end
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if data == nil then
    self:close_self()
    return
  end
  if string.is_valid(data.image) then
    UIUtil.set_image(self._img_icon_dynamic, data.image, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_title_dynamic, data.title or "")
  UIUtil.set_text(self._txt_info_dynamic, data.info or "")
end

return M
