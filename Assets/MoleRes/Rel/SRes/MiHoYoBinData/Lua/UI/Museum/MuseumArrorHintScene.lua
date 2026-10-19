local M = G.Class("MuseumArrorHintScene", G.UIPanel)
local base = G.UIPanel
local HINT_DISTANCE = 0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Museum/MuseumArrorHintScene"
  self.config.type = EUIType.Scene
  self._hint_order = overhead_hint_module.overhead_hint_order.arrow
  self._tbl_hint_cache = {}
  self._tbl_cur_show_hint = {}
end

function M:on_create()
  base.on_create(self)
  self:add_evt_listener(EventID.LuaSetLoadingState, function()
    self:_remove_all_hint()
  end)
end

function M:on_open()
  base.on_open(self)
  local data = self:get_extra_data() or {}
  self:set_hint(data.guid)
end

function M:on_close()
  base.on_close(self)
  self:_remove_all_hint()
end

function M:on_destroy()
  self:_remove_all_hint()
  base.on_destroy(self)
end

function M:set_hint(guid)
  if is_null(guid) or guid == 0 then
    self:_remove_all_hint()
    return
  end
  for cur_guid, _ in pairs(self._tbl_cur_show_hint) do
    if cur_guid ~= guid then
      self:_remove_hint(cur_guid)
    end
  end
  self:_add_hint(guid)
end

function M:_add_hint(guid)
  if is_null(guid) or guid == 0 or self._tbl_cur_show_hint[guid] ~= nil then
    return
  end
  local trans = self:_get_hint_item()
  self._tbl_cur_show_hint[guid] = trans
  UIUtil.set_active(trans, true)
  overhead_hint_module:add_overhand_hint_by_guid(guid, self._hint_order, trans, HINT_DISTANCE)
end

function M:_remove_hint(guid)
  if is_null(guid) or guid == 0 then
    self:_remove_all_hint()
    return
  end
  local trans = self._tbl_cur_show_hint[guid]
  if trans == nil then
    return
  end
  overhead_hint_module:remove_overhand_hint(guid, self._hint_order)
  UIUtil.set_active(trans, false)
  table.insert(self._tbl_hint_cache, trans)
  self._tbl_cur_show_hint[guid] = nil
end

function M:remove_hint_item(guid)
  self:_remove_hint(guid)
end

function M:_remove_all_hint()
  for guid, trans in pairs(self._tbl_cur_show_hint) do
    overhead_hint_module:remove_overhand_hint(guid, self._hint_order)
    UIUtil.set_active(trans, false)
    table.insert(self._tbl_hint_cache, trans)
  end
  self._tbl_cur_show_hint = {}
end

function M:_get_hint_item()
  if #self._tbl_hint_cache <= 0 then
    local obj = UIUtil.load_prefab_set_parent(self._obj_item_hint, self._trans_parent, nil, true)
    return obj.transform
  end
  local trans = self._tbl_hint_cache[1]
  table.remove(self._tbl_hint_cache, 1)
  return trans
end

function M:is_idle()
  return next(self._tbl_cur_show_hint) == nil
end

return M
