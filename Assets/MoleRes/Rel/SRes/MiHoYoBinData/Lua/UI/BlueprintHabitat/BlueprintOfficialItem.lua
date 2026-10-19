local M = G.Class("BlueprintOfficialItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._cfg = nil
  self._btn_item = nil
  self._img_pic = nil
  self._txt_name = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_item) then
    self:bind_callback(self._btn_item, pack(self, M._on_btn_item_click))
  end
end

function M:refresh(cfg)
  self._cfg = cfg
  if cfg == nil then
    return
  end
  UIUtil.set_image(self._img_pic, cfg.tooltableicon, self:get_load_proxy())
  UIUtil.set_text(self._txt_name, cfg.name)
  self:_refresh_red_point()
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  if self._cfg == nil then
    self._red_point:ShowRedPoint(RedPointType.None)
    return
  end
  local red_state = RedPointType.None
  if not new_blueprint_module:is_blueprint_unlock_recorded(self._cfg.id) then
    red_state = RedPointType.NewRp
    new_blueprint_module:record_blueprint_unlock(self._cfg.id)
  end
  self._red_point:ShowRedPoint(red_state)
end

function M:_on_btn_item_click()
  if self._cfg == nil then
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintInfoPage", {
    blueprint_id = self._cfg.id
  })
end

return M
