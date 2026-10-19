local M = G.Class("RabbitTabletopChangeColorWheel", G.UIPanel)
local base = G.UIPanel
local TOGGLE_SUIT_LIST = {
  {
    key = "_tog_top",
    suit = TutuCardSuit.Green
  },
  {
    key = "_tog_right",
    suit = TutuCardSuit.Yellow
  },
  {
    key = "_tog_bottom",
    suit = TutuCardSuit.Blue
  },
  {
    key = "_tog_left",
    suit = TutuCardSuit.Red
  }
}

function M:on_create()
  base.on_create(self)
  self._selected_suit = nil
  self:clear_selected_suit()
  self:_bind_toggles()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:clear_selected_suit()
  self._selected_suit = nil
  for _, entry in ipairs(TOGGLE_SUIT_LIST) do
    self[entry.key]:SetIsOnWithoutNotify(false)
  end
end

function M:_bind_toggles()
  for _, entry in ipairs(TOGGLE_SUIT_LIST) do
    local suit = entry.suit
    self:bind_callback(self[entry.key], function(is_on)
      if is_on then
        self:_on_color_selected(suit)
      end
    end)
  end
end

function M:_on_color_selected(suit)
  self._selected_suit = suit
  self.holder:choosing_color(suit)
end

function M:get_selected_suit()
  return self._selected_suit
end

function M:show_selected_suit(suit)
  for _, entry in ipairs(TOGGLE_SUIT_LIST) do
    self[entry.key]:SetIsOnWithoutNotify(entry.suit == suit)
  end
end

function M:set_interactable(interactable)
  for _, entry in ipairs(TOGGLE_SUIT_LIST) do
    self[entry.key].interactable = interactable
  end
end

return M
