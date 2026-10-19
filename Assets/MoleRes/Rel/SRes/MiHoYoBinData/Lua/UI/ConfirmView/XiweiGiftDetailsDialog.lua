local M = G.Class("XiweiGiftDetailsDialog", "UI/ConfirmView/CommonGiftDetailsDialog")
local base = G.CommonGiftDetailsDialog
local item_v2_cls = item_module.item_v2_panel_cls_name
local UI_CLASS_PATH = "UI/ConfirmView/XiweiGiftDetailsDialog"
local FUKUBAG_CFG_ROW_ID = 1
local TRACKER_REMOVE_WHEN_DONE = 1
local EXTRA_DROP_TITLE_TEXT_ID = "SpringFestival_SpecialTitle"
local state_canbuy = {
  can_buy = 0,
  view_only = 1,
  extra_drop = 2
}
local EMPTY_TABLE = {}
local _gift_box_whitelist_cache

local function _get_fukubag_cfg_row()
  local fuku_cfg_type = not BFukuBagCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BFukuBagCfg
  if fuku_cfg_type == nil then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(fuku_cfg_type), FUKUBAG_CFG_ROW_ID)
end

local function _get_gift_box_whitelist()
  if _gift_box_whitelist_cache ~= nil then
    return _gift_box_whitelist_cache
  end
  local row = _get_fukubag_cfg_row()
  if row == nil then
    return EMPTY_TABLE
  end
  local whitelist = {}
  for piece in string.gmatch(row.xiweigift or "", "([^,%s]+)") do
    local box_id = tonumber(piece)
    if box_id ~= nil and 0 < box_id then
      whitelist[box_id] = true
    end
  end
  _gift_box_whitelist_cache = whitelist
  return whitelist
end

local function _resolve_node_state(row)
  local tracker_id = row.requiredglobaltrackerid or 0
  if tracker_id == 0 then
    return true, false
  end
  local is_remove_mode = (row.globaltrackerremovewhendone or 0) == TRACKER_REMOVE_WHEN_DONE
  if CsTrackerModuleUtil == nil then
    return is_remove_mode, false
  end
  local is_goal_done = CsTrackerModuleUtil.IsSatisfyActionCondition(tracker_id) == true
  if is_remove_mode then
    return not is_goal_done, false
  end
  return is_goal_done, is_goal_done
end

local function _sort_by_rank_desc(items)
  table.sort(items, function(a, b)
    local cfg_a = item_module:get_cfg_by_id(a.config_id)
    local cfg_b = item_module:get_cfg_by_id(b.config_id)
    local rank_a = cfg_a and cfg_a.rank or 0
    local rank_b = cfg_b and cfg_b.rank or 0
    return rank_a > rank_b
  end)
end

function M.is_in_gift_box_whitelist(box_id)
  box_id = tonumber(box_id) or 0
  if box_id <= 0 then
    return false
  end
  return _get_gift_box_whitelist()[box_id] == true
end

function M.try_open(box_id, extra_data)
  if not M.is_in_gift_box_whitelist(box_id) then
    return false
  end
  local data = extra_data or {}
  data.box_id = tonumber(box_id)
  UIManagerInstance:open(UI_CLASS_PATH, data)
  return true
end

function M:init()
  base.init(self)
  self._extra_drop_entries = {}
  self._sub_list_binder = nil
end

function M:on_enable()
  local raw_data = self:get_extra_data() or {}
  local box_id = tonumber(raw_data.box_id) or 0
  local normal_items, extra_drop_items = self:_resolve_pool_items(box_id)
  self:_inject_gift_box_data(raw_data, box_id, normal_items)
  self.config.extra_data = raw_data
  local is_first_list_init = not self._gift_list_inited
  base.on_enable(self)
  self:_refresh_extra_drop_items(extra_drop_items)
  self:_refresh_extra_drop_title()
  self:_apply_extra_drop_state(0 < #extra_drop_items)
  if is_first_list_init then
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      if not_null(self.game_obj) and not_null(self._scroll_item_list) then
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
        self:_refresh_items()
      end
    end)
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_refresh_extra_drop_items(EMPTY_TABLE)
end

function M:_inject_gift_box_data(extra_data, box_id, normal_items)
  if extra_data.items == nil then
    extra_data.items = normal_items
  end
  if extra_data.gift_item_id == nil then
    extra_data.gift_item_id = box_id
  end
  if extra_data.title == nil then
    local item_cfg = item_module:get_cfg_by_id(box_id)
    extra_data.title = item_cfg and item_cfg.name or ""
  end
  if extra_data.content_desc == nil then
    extra_data.content_desc = UIUtil.get_text_by_id("Curio_Emporium_Good_Included_Tip")
  end
  if extra_data.view_only == nil then
    extra_data.view_only = true
  end
end

function M:_resolve_pool_items(box_id)
  local normal_items = {}
  local extra_drop_items = {}
  if box_id <= 0 then
    return normal_items, extra_drop_items
  end
  local box_cfg = ExcelDataUtil.get_value(typeof(BItemUseCfg), box_id)
  if box_cfg == nil then
    return normal_items, extra_drop_items
  end
  local pool_id = tonumber(box_cfg.effectparams)
  if pool_id == nil then
    return normal_items, extra_drop_items
  end
  local pool = (ExcelDataUtil.get_table(typeof(BRandomPoolCfg)) or {})[pool_id]
  if pool == nil then
    return normal_items, extra_drop_items
  end
  for _, row in ipairs(pool) do
    local droppable, is_extra_drop = _resolve_node_state(row)
    if droppable then
      local group = is_extra_drop and extra_drop_items or normal_items
      table.insert(group, {
        config_id = row.configid,
        num = row.num
      })
    end
  end
  _sort_by_rank_desc(normal_items)
  _sort_by_rank_desc(extra_drop_items)
  return normal_items, extra_drop_items
end

function M:_refresh_extra_drop_title()
  if is_null(self._text_specialtitle) then
    return
  end
  if not UIUtil.is_valid_text_id(EXTRA_DROP_TITLE_TEXT_ID) then
    Logger.Log("[XiweiGiftDetailsDialog] text id not in TextMap yet: " .. EXTRA_DROP_TITLE_TEXT_ID)
    return
  end
  UIUtil.set_text_by_id(self._text_specialtitle, EXTRA_DROP_TITLE_TEXT_ID)
end

function M:_apply_extra_drop_state(has_extra_drop)
  if is_null(self._ui_state_group_state_canbuy) then
    return
  end
  if has_extra_drop then
    self._ui_state_group_state_canbuy:SetState(state_canbuy.extra_drop)
    return
  end
  self._ui_state_group_state_canbuy:SetState(self._view_only and state_canbuy.view_only or state_canbuy.can_buy)
end

function M:_refresh_extra_drop_items(items)
  local binder = self:_get_sub_list_binder()
  if binder == nil then
    Logger.Log("[XiweiGiftDetailsDialog] _layout_sublist is nil, skip extra drop refresh.")
    return
  end
  for i, item_data in ipairs(items) do
    local entry = self._extra_drop_entries[i]
    if entry == nil then
      local obj = binder:AddItem(0)
      if not_null(obj) then
        entry = {
          obj = obj,
          panel = self:add_panel(item_v2_cls, obj),
          item_data = nil
        }
        self._extra_drop_entries[i] = entry
        local btn = entry.panel and entry.panel:get_btn() or nil
        if not_null(btn) then
          self:bind_callback(btn, function()
            local data = entry.item_data
            if data ~= nil then
              self:_on_item_click(data.config_id)
            end
          end)
        end
      end
    end
    if entry ~= nil and not_null(entry.obj) and entry.panel ~= nil then
      entry.item_data = item_data
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_item_data(item_data.config_id, nil)
    end
  end
  for i = #items + 1, #self._extra_drop_entries do
    local entry = self._extra_drop_entries[i]
    if entry ~= nil and not_null(entry.obj) then
      entry.item_data = nil
      UIUtil.set_active(entry.obj, false)
    end
  end
end

function M:_get_sub_list_binder()
  if self._sub_list_binder ~= nil then
    return self._sub_list_binder
  end
  if self._layout_sublist and self._layout_sublist.AddItem ~= nil then
    self._sub_list_binder = self._layout_sublist
    return self._sub_list_binder
  end
  return nil
end

return M
