local M = G.Class("CookWareItemView", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._cookware_id = 0
  if not_null(self._obj_item_v2_basic) then
    local btn = UIUtil.find_button(self._obj_item_v2_basic)
    if not_null(btn) then
      self:bind_callback(btn, pack(self, M._on_click))
    end
  end
end

function M:set_visible(visible)
  UIUtil.set_active(self.trans, visible)
end

function M:refresh(info, load_proxy)
  local locked = info.locked
  self._cookware_id = info.cookware_id or 0
  if not_null(self._txt_cookware_title) then
    UIUtil.set_text(self._txt_cookware_title, info.title or "")
  end
  if not_null(self._txt_cookware) then
    UIUtil.set_text(self._txt_cookware, info.value or "")
  end
  if not locked and self._cookware_id > 0 then
    self:_refresh_item_icon(load_proxy)
  elseif self._item_cls ~= nil then
    item_module:set_item_cls(self._item_cls, 0, 0, load_proxy, nil, true)
  end
  self:_apply_lock_state(locked)
end

function M:_refresh_item_icon(load_proxy)
  local icon_img = self._img_icon_dynamic
  if is_null(icon_img) then
    return
  end
  local cls_root = icon_img.transform.parent
  if is_null(cls_root) then
    return
  end
  if self._item_cls == nil then
    self._item_cls = item_module:init_item_cls(cls_root)
  end
  if self._item_cls == nil then
    return
  end
  item_module:set_item_cls(self._item_cls, self._cookware_id, 0, load_proxy, nil, true)
end

function M:_on_click()
  if self._cookware_id > 0 then
    item_module:open_item_info_dialog_by_data({
      cfg_id = self._cookware_id,
      owned_num = CsCookModuleUtil.CookwareIsUnlock(self._cookware_id) and 1 or 0
    })
  end
end

function M:_apply_lock_state(locked)
  local sg = self._ui_state_group_lock or self._state_group_lock
  if not_null(sg) then
    sg:SetState(locked and 0 or 1)
  end
end

return M
