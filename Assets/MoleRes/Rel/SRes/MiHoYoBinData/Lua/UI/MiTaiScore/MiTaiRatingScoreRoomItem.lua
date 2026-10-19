local M = G.Class("MiTaiRatingScoreRoomItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._sprite = nil
  self._selected = nil
  self._has_selection = nil
  self._score_state_value = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn, pack(self, M._on_click))
  self:set_selected(false)
end

function M:set_selected(selected, has_selection)
  has_selection = has_selection == true
  if self._selected == selected and self._has_selection == has_selection then
    return
  end
  self._selected = selected
  self._has_selection = has_selection
  if not_null(self._outline) then
    self._outline.enabled = selected
  end
  if not_null(self._img_icon) then
    self._img_icon.color = not (not has_selection or selected) and Color(0.5, 0.5, 0.5, 1) or Color(1, 1, 1, 1)
  end
end

function M:set_interactable(interactable)
  if not_null(self._btn) then
    self._btn.interactable = interactable
  end
end

function M:set_score_state(state)
  if self._score_state_value == state then
    return
  end
  self._score_state_value = state
  self._score_state:SetState(state)
end

function M:on_destroy()
  self:_clear_sprite()
  base.on_destroy(self)
end

function M:refresh(room_data, index, on_click, preferred_width)
  self._room_data = room_data
  self._index = index
  self._on_click_callback = on_click
  self._layout_element.preferredWidth = preferred_width
  UIUtil.set_text_by_id(self._txt_score, "MitaiScore_ScoreTitle2", TextMapFormatUtil.FormatInteger(room_data.score or 0))
  self:_clear_sprite()
  local texture = room_data and room_data.texture or nil
  if is_null(texture) then
    self._img_icon.sprite = nil
    return
  end
  self._sprite = Sprite.Create(texture, Rect(0, 0, texture.width, texture.height), Vector2(0.5, 0.5))
  self._img_icon.sprite = self._sprite
  self._img_icon.alphaHitTestMinimumThreshold = 0.1
end

function M:reset()
  self:_clear_sprite()
  self._img_icon.sprite = nil
  self._room_data = nil
  self._index = nil
  self._on_click_callback = nil
  UIUtil.set_text(self._txt_score, "")
  self:set_score_state(0)
  self:set_selected(false)
end

function M:_on_click()
  if self._on_click_callback then
    self._on_click_callback(self._index, self._room_data)
  end
end

function M:_clear_sprite()
  if not_null(self._sprite) then
    CS.UnityEngine.Object.Destroy(self._sprite)
    self._sprite = nil
  end
end

return M
