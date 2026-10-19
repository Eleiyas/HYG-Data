local M = G.Class("StarEtiquetteTipsDialog", G.UIWindow)
local base = G.UIWindow
local AUTO_CLOSE_DELAY_SECONDS = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteTipsDialog"
  self.config.type = EUIType.Tip
  self.config.input_penetrate = true
end

function M:on_create()
  base.on_create(self)
  self._remain_time = 0
end

function M:on_enable()
  base.on_enable(self)
  self._remain_time = AUTO_CLOSE_DELAY_SECONDS
  local extra_data = self:get_extra_data()
  if type(extra_data) ~= "table" then
    UIUtil.set_text(self._txt_info, "")
    return
  end
  UIUtil.set_text_by_id(self._txt_info, extra_data.text_id)
end

function M:update(delta_time)
  if self._remain_time <= 0 then
    return
  end
  self._remain_time = self._remain_time - delta_time
  if self._remain_time <= 0 then
    self:close_self()
  end
end

return M
