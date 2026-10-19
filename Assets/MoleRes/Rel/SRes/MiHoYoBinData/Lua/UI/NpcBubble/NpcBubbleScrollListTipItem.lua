local M = G.Class("NpcBubbleScrollListTipItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  self._guid = nil
end

function M:refresh(data)
  self._guid = data.guid
  UIUtil.set_text(self._txt, data.text or "")
  if string.is_valid(data.icon_path) then
    UIUtil.set_image(self._img_head, data.icon_path, self:get_load_proxy())
  else
    self._img_head.sprite = nil
  end
end

function M:reset()
  self._guid = nil
  UIUtil.set_text(self._txt, "")
  self._img_head.sprite = nil
end

function M:get_guid()
  return self._guid
end

return M
