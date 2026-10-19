local M = G.Class("NpcDispatchOptionStackDialog", "UI/PacketView/OptionStack/PacketOptionStackDialog")
local base = G.PacketOptionStackDialog

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_set_title()
  self:_hide_now_select_objs()
end

function M:_refresh()
  base._refresh(self)
end

function M:_hide_now_select_objs()
  if not_null(self._trans_select) then
    UIUtil.set_active(self._trans_select, false)
  end
end

function M:_set_title()
  UIUtil.set_text_by_id(self._txt_title, "DispatchPacketPage_txt_supplies_9")
end

return M
