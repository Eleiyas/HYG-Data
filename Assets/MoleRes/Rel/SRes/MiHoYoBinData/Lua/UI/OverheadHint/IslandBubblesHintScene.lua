local M = G.Class("IslandBubblesHintScene", G.UIPanel)
local base = G.UIPanel
local island_bubble_item_cls_name = "UI/OverheadHint/IslandBubbleItem"
local HINT_DISTANCE = 0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/OverheadHint/IslandBubblesHintScene"
  self.config.type = EUIType.Scene
  self._hint_order = overhead_hint_module.overhead_hint_order.gentle_hint
  self._tbl_hint_cache = {}
  self._tbl_cur_show_hint = {}
end

function M:on_create()
  base.on_create(self)
  self:add_evt_listener(EventID.LuaHideIslandBubble, function(guid)
    self:_remove_hint(guid)
  end)
  self:add_evt_listener(EventID.LuaSetLoadingState, function(is_loading)
    if is_loading then
      self:_remove_all_hint()
    else
      self:_remove_all_hint()
      CsStarSeaManagerV2Util.ResyncIslandBubbles()
    end
  end)
end

function M:on_open()
  base.on_open(self)
  local data = self:get_extra_data() or {}
  if data.guid then
    self:_add_hint(data.guid)
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
  self:_remove_all_hint()
end

function M:on_destroy()
  self:_remove_all_hint()
  base.on_destroy(self)
end

function M:_add_hint(info)
  local guid = type(info) == "table" and info.guid or info
  if is_null(guid) or guid == 0 then
    return
  end
  local data = self:get_extra_data() or {}
  local info_tbl = type(info) == "table" and info or {}
  local island_id = info_tbl.islandId or data.islandId or 0
  local item = self._tbl_cur_show_hint[guid]
  if item == nil then
    item = self:_get_hint_item()
    self._tbl_cur_show_hint[guid] = item
    overhead_hint_module:add_overhand_hint_by_guid(guid, self._hint_order, item:get_trans(), HINT_DISTANCE)
    UIUtil.set_active(item:get_trans(), true)
  end
  item:set_data({
    guid = guid,
    islandId = island_id,
    isVisit = info_tbl.isVisit ~= nil and info_tbl.isVisit or data.isVisit,
    curCollection = info_tbl.curCollection or data.curCollection,
    totalCollection = info_tbl.totalCollection or data.totalCollection
  })
end

function M:_remove_hint(guid)
  if is_null(guid) or guid == 0 then
    self:_remove_all_hint()
    return
  end
  local item = self._tbl_cur_show_hint[guid]
  if item == nil then
    return
  end
  overhead_hint_module:remove_overhand_hint(guid, self._hint_order)
  table.insert(self._tbl_hint_cache, item)
  self._tbl_cur_show_hint[guid] = nil
end

function M:remove_hint_item(guid)
  self:_remove_hint(guid)
end

function M:_remove_all_hint()
  for guid, item in pairs(self._tbl_cur_show_hint) do
    overhead_hint_module:remove_overhand_hint(guid, self._hint_order)
    table.insert(self._tbl_hint_cache, item)
  end
  self._tbl_cur_show_hint = {}
end

function M:_get_hint_item()
  if #self._tbl_hint_cache <= 0 then
    local obj = UIUtil.load_prefab_set_parent(self._item_bubble_item, self._trans_bubble_parent, nil, true)
    UIUtil.set_active(obj, false)
    local cls = self:add_panel(island_bubble_item_cls_name, obj.transform)
    return cls
  end
  local cls = self._tbl_hint_cache[1]
  table.remove(self._tbl_hint_cache, 1)
  return cls
end

function M:is_idle()
  return next(self._tbl_cur_show_hint) == nil
end

return M
