local M = G.Class("SpringFestivalEmbroideredPage", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalPageBase")
local base = G.SpringFestivalPageBase

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_embroideredPage"
  self._page_key = spring_festival_activity_module.page_key.embroidered
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_rule) then
    self:bind_callback(self._btn_rule, pack(self, M._on_btn_rule_click))
  end
end

function M:refresh()
  base.refresh(self)
  self:refresh_reward_list(self._layout_itemreward)
end

function M:_on_btn_rule_click()
  self:open_introduction_dialog()
end

function M:get_tracking_target()
  return spring_festival_activity_module:get_embroidered_tracking_target()
end

return M
