local M = G.Class("RiddleChatBubbleLitePanel", G.UIBase)
local base = G.UIBase
local BubbleState = {
  SelfTyping = 0,
  SelfSpeaking = 1,
  SelfSpeakingTyping = 2,
  OtherTyping = 3,
  OtherSpeaking = 4,
  OtherSpeakingTyping = 5,
  Emoji = 6
}
local DEFAULT_STATE = BubbleState.OtherSpeaking

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(text, state, x, y, show)
  UIUtil.set_active(self.game_obj, show == true)
  if show ~= true then
    return
  end
  self:set_text(text)
  self:set_state(state)
  self:set_pos(x, y)
end

function M:set_text(text)
  if not is_null(self._text) then
    UIUtil.set_text(self._text, text or "")
  end
end

function M:set_state(state)
  local bubble_state = tonumber(state) or DEFAULT_STATE
  if bubble_state < BubbleState.SelfTyping or bubble_state > BubbleState.Emoji then
    bubble_state = DEFAULT_STATE
  end
  if not is_null(self._chat_state) then
    self._chat_state:SetState(bubble_state)
  end
end

function M:set_pos(x, y)
  if not is_null(self.rect_trans) then
    self.rect_trans.anchoredPosition = Vector2(tonumber(x) or 0, tonumber(y) or 0)
  end
end

return M
