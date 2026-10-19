local M = G.Class("LittleCornerTagItem", G.UIBase)
local base = G.UIBase

function M:init()
  self._tag_id = 0
  base.init(self)
  self._txt_tag = nil
  self._btn_tag = nil
  self._txt_tips = nil
  self._state_tag = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_tag, function()
    local draft_tags = little_corner_module:get_draft_tags()
    UIManagerInstance:open("UI/LittleCorner/LittleCornerTagChooseDialog", {default_tags = draft_tags})
  end)
end

function M:on_open()
  base.on_open(self)
  self._tag_id = self:get_extra_data()
  self:_refresh_ui()
end

function M:_refresh_ui()
  if self._state_tag then
    self._state_tag:SetState(self._tag_id == 0 and 0 or 1)
  end
  if self._tag_id ~= 0 then
    local tag_name = little_corner_module:get_tag_name(self._tag_id)
    UIUtil.set_text(self._txt_tag, tag_name)
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:force_refresh(tag_id)
  self._tag_id = tag_id
  self:_refresh_ui()
end

function M:set_interactable(interactable)
  if not_null(self._btn_tag) then
    self._btn_tag.interactable = interactable
  end
end

return M
