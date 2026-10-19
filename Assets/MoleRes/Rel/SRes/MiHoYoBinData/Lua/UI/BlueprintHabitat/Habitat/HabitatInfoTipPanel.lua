local tip_item_cls = "UI/BlueprintHabitat/Habitat/HabitatInfoTipItem"
local M = G.Class("HabitatInfoTipPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:set_active(false)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:show_id(cfg_id, count)
  self:set_active(true)
  self:_refresh({
    {
      cfg_id or 0,
      count or 0
    }
  })
end

function M:show_tag(pairs_list)
  self:set_active(true)
  self:_refresh(pairs_list or {})
end

function M:hide()
  self:set_active(false)
end

function M:set_trans_pos(x, y, z)
  if is_null(self._trans_pos) then
    return
  end
  self._trans_pos:SetPosition(x, y, z)
end

function M:_refresh(pairs_list)
  for i = 1, #pairs_list do
    local cfg_id = pairs_list[i][1] or 0
    local count = pairs_list[i][2] or 0
    local cls = self._items[i]
    if cls == nil then
      local obj = self._list_item:AddItem(0)
      cls = self:add_panel(tip_item_cls, obj)
      self._items[i] = cls
    end
    cls:set_active(true)
    cls:refresh(cfg_id, count)
  end
  for i = #pairs_list + 1, #self._items do
    self._items[i]:set_active(false)
  end
end

function M:_on_btn_close_click()
  self:hide()
end

return M
