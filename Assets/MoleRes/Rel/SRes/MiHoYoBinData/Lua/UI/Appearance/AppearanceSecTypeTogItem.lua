local M = G.Class("AppearanceSecTypeTogItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._id = -1
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh(id)
  if id == nil or id < 0 then
    self:set_active(false)
    return
  end
  self._id = id
  self:set_active(true)
  local cfg = ExcelDataUtil.get_value(typeof(BChangeOutfitCfg), id)
  if is_null(cfg) then
    self:set_active(false)
    return
  end
  UIUtil.set_image(self._img_select_icon, cfg.scetypeicon, self:get_load_proxy())
  UIUtil.set_image(self._img_unselect_icon, cfg.scetypeicon, self:get_load_proxy())
  self:set_grey(false)
end

function M:get_tog()
  return self._tog
end

function M:get_id()
  return self._id
end

function M:set_grey(is_grey)
  if not_null(self._tog) then
    self._tog.interactable = not is_grey
  end
end

function M:play_is_on_anim()
  UIUtil.set_active(self._obj_bag_type, false)
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    UIUtil.set_active(self._obj_bag_type, true)
  end)
end

return M
