local item_v2_cls = item_module.item_v2_panel_cls_name
local M = G.Class("SpringFestivalBarteringItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._item_panel = nil
  self._item_id = 0
  self._item_count = 0
  self._npc_id = 0
  self._is_last = false
  self._obj_item_v2_basic = nil
  self._obj_line = nil
  self._img_npc_head = nil
  self._txt_num = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._obj_item_v2_basic) then
    self._item_panel = self:add_panel(item_v2_cls, self._obj_item_v2_basic)
  end
end

function M:set_data(item_id, item_count, npc_id, is_last)
  self._item_id = item_id or 0
  self._item_count = item_count or 0
  self._npc_id = npc_id or 0
  self._is_last = is_last or false
  self:_refresh_ui()
end

function M:_refresh_ui()
  if self._item_panel ~= nil then
    if self._item_id ~= 0 then
      self._item_panel:set_active(true)
      self._item_panel:set_item_data(self._item_id, self._item_count)
      self._item_panel:bind_item_info_btn(self._item_id)
    else
      self._item_panel:set_active(false)
    end
  end
  if not is_null(self._txt_num) and self._item_count <= 1 then
    local txt
    if 0 >= self._item_count then
      txt = string.format("<style=TextWarning_Dark>%d</style>", self._item_count)
    elseif self._item_count == 1 then
      txt = tostring(self._item_count)
    end
    UIUtil.set_active(self._txt_num, true)
    UIUtil.set_text(self._txt_num, txt)
  end
  if not is_null(self._img_npc_head) then
    UIUtil.set_active(self._img_npc_head.gameObject, false)
  end
  if not is_null(self._obj_line) then
    UIUtil.set_active(self._obj_line, not self._is_last)
  end
end

return M
