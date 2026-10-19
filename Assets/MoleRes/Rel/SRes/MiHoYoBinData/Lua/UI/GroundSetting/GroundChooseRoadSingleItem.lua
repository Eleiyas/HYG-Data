local M = G.Class("GroundChooseRoadSingleItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._cfg_id = -1
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._tog_click) then
    self:bind_callback(self._tog_click, pack(self, M._on_tog_click))
  end
end

function M:_on_tog_click(is_on)
  if not is_on or self._cfg_id < 0 then
    return
  end
  CsGroundSettingModuleUtil.SetCurRoadCfgId(self._cfg_id)
  if self.holder and self.holder.refresh_select_slot then
    self.holder:refresh_select_slot(self._index, self._cfg_id)
  end
end

function M:refresh(index, cfg)
  self._index = index
  if not cfg or not cfg.id then
    self._cfg_id = 0
    UIUtil.set_image(self._img_icon, "UISprite/Load/GroundSetting/Img_GroundSetting_01", self:get_load_proxy())
  else
    self._cfg_id = cfg.id
    UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
  end
  self._tog_click:SetIsOnWithoutNotify(self._cfg_id == self.holder.select_cfg_id)
end

return M
