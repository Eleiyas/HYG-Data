local M = G.Class("LittleCornerTagChooseGroupItem", G.UIPanel)
local base = G.UIPanel
local tag_item_cls = "UI/LittleCorner/LittleCornerTagChooseGroupTagItem"

function M:init()
  base.init(self)
  self._txt_title = nil
  self._txt_group_title = nil
  self._list_item_binder = nil
  self._tag_items = {}
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  self:_refresh_ui()
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if not data then
    return
  end
  local group_cfg = data.group_cfg
  local dialog = data.dialog
  UIUtil.set_text(self._txt_group_title, group_cfg.title)
  local tag_count = group_cfg.tagsLength
  for i = 0, tag_count - 1 do
    local tag_id = group_cfg:tags(i)
    local idx = i + 1
    local item = self._tag_items[idx]
    if not item then
      local obj = self._list_item_binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(tag_item_cls, obj, {tag_id = tag_id, dialog = dialog})
        self._tag_items[idx] = item
        UIUtil.set_active(obj, true)
      end
    else
      item:set_extra_data({tag_id = tag_id, dialog = dialog})
      item:force_refresh()
      UIUtil.set_active(item.game_obj, true)
    end
  end
  for i = tag_count + 1, #self._tag_items do
    if self._tag_items[i] then
      UIUtil.set_active(self._tag_items[i].game_obj, false)
    end
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

return M
