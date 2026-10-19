local M = G.Class("RecipeItemTwotabView", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(icon1, icon2, locked, load_proxy)
  if not_null(self._img_icon) then
    if locked then
      UIUtil.set_active(self._img_icon, false)
    else
      UIUtil.set_active(self._img_icon, true)
      if string.is_valid(icon1) then
        UIUtil.set_image(self._img_icon, icon1, load_proxy)
      end
    end
  end
  if not_null(self._img_icon_2) then
    if locked then
      UIUtil.set_active(self._img_icon_2, false)
    else
      UIUtil.set_active(self._img_icon_2, true)
      if string.is_valid(icon2) then
        UIUtil.set_image(self._img_icon_2, icon2, load_proxy)
      end
    end
  end
  self:_apply_lock_state(locked)
end

function M:set_click_params(item_index, callback)
  self._item_index = item_index
  self._click_callback = callback
  if not_null(self._btn_icon) then
    self:bind_callback(self._btn_icon, pack(self, M._on_btn1_click))
  end
  if not_null(self._btn_icon_2) then
    self:bind_callback(self._btn_icon_2, pack(self, M._on_btn2_click))
  end
end

function M:_on_btn1_click()
  if self._click_callback then
    local anchor = not_null(self._btn_icon) and self._btn_icon.transform or self.trans
    self._click_callback(self._item_index, 1, anchor)
  end
end

function M:_on_btn2_click()
  if self._click_callback then
    local anchor = not_null(self._btn_icon_2) and self._btn_icon_2.transform or self.trans
    self._click_callback(self._item_index, 2, anchor)
  end
end

function M:_apply_lock_state(locked)
  if not_null(self._state_group_lock) then
    self._state_group_lock:SetState(locked and 0 or 1)
  end
end

return M
