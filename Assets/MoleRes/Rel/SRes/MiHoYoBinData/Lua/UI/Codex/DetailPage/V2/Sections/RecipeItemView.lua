local M = G.Class("RecipeItemView", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(icon, locked, load_proxy)
  if not_null(self._img_icon) then
    if locked then
      UIUtil.set_active(self._img_icon, false)
    else
      UIUtil.set_active(self._img_icon, true)
      if string.is_valid(icon) then
        UIUtil.set_image(self._img_icon, icon, load_proxy)
      end
    end
  end
  self:_apply_lock_state(locked)
end

function M:set_click_params(item_index, tag_index, callback)
  self._item_index = item_index
  self._tag_index = tag_index
  self._click_callback = callback
  if not_null(self._btn) then
    self:bind_callback(self._btn, pack(self, M._on_btn_click))
  end
end

function M:_on_btn_click()
  if self._click_callback then
    local anchor = not_null(self._btn) and self._btn.transform or self.trans
    self._click_callback(self._item_index, self._tag_index, anchor)
  end
end

function M:_apply_lock_state(locked)
  if not_null(self._state_group_lock) then
    self._state_group_lock:SetState(locked and 0 or 1)
  end
end

return M
