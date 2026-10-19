local M = G.Class("NpcBubbleScrollListTip", G.UIPanel)
local base = G.UIPanel
local bubble_tip_data = require("UI/NpcBubble/NpcBubbleScrollListTipData")
local item_cls = "UI/NpcBubble/NpcBubbleScrollListTipItem"
local slide_duration = 0.2
local slide_epsilon = 0.5

local function apply_slide(slide)
  if is_null(slide.rect_trans) then
    return false
  end
  local current = slide.rect_trans.anchoredPosition
  if slide.applied_y ~= nil and math.abs(current.y - slide.applied_y) > 0.01 then
    slide.target_x = current.x
    slide.target_y = current.y
  end
  local progress = slide.elapsed / slide_duration
  if 1 <= progress then
    slide.rect_trans.anchoredPosition = Vector2(slide.target_x, slide.target_y)
    slide.applied_y = slide.target_y
    return false
  end
  local remain = 1 - progress
  local y = slide.target_y + slide.offset * remain * remain * remain
  slide.rect_trans.anchoredPosition = Vector2(slide.target_x, y)
  slide.applied_y = y
  return true
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcBubble/NpcBubbleScrollListTip"
  self._active_items = {}
  self._item_cache = {}
  self._exiting_items = {}
  self._slides = {}
  self._order_signature = ""
  self._max_count = nil
  self._main_page_active = false
  self._has_edge_bubble = false
  self._is_occluded = false
end

function M:on_create()
  base.on_create(self)
  self._state:SetState(0)
  self._canvas_group.alpha = 0
  self._canvas_group.interactable = false
  self._canvas_group.blocksRaycasts = false
  local main_page = UIManagerInstance:get_window_by_class("UI/MainPage/MainPage")
  self._main_page_active = main_page ~= nil and main_page.is_active
  bubble_tip_data:bind_view(self)
end

function M:on_enable()
  base.on_enable(self)
  bubble_tip_data:bind_view(self)
end

function M:on_destroy()
  for _, item in ipairs(self._exiting_items) do
    if item._has_binder and not is_null(item.binder) then
      item.binder:StopAnimation(true)
    end
    if item.is_active then
      item:set_active(false, true)
    end
  end
  table.clear(self._exiting_items)
  bubble_tip_data:unbind_view(self)
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.dispatch_main_page_active, pack(self, M._on_main_page_active_changed))
end

function M:_on_main_page_active_changed(is_active)
  self._main_page_active = is_active
  self:_refresh_visual_active()
end

function M:_should_visual_active()
  return self._main_page_active and self._has_edge_bubble
end

function M:_refresh_visual_active()
  if is_null(self._canvas_group) then
    return
  end
  local should_active = self:_should_visual_active()
  if should_active then
    self._canvas_group.alpha = 1
    self._canvas_group.interactable = true
    self._canvas_group.blocksRaycasts = true
    self._state:SetState(self._is_occluded and 1 or 0)
  else
    self._canvas_group.alpha = 0
    self._canvas_group.interactable = false
    self._canvas_group.blocksRaycasts = false
  end
end

function M:_refresh_list_active()
  local has_item = next(self._active_items) ~= nil or #self._exiting_items > 0
  self._has_edge_bubble = has_item
  UIUtil.set_active(self._list.gameObject, has_item)
  self:_refresh_visual_active()
end

function M:_ensure_list_visible()
  self._has_edge_bubble = true
  UIUtil.set_active(self._list.gameObject, true)
  self:_refresh_visual_active()
end

function M:_for_each_visual_item(callback)
  for _, item in pairs(self._active_items) do
    callback(item)
  end
  for _, item in ipairs(self._exiting_items) do
    callback(item)
  end
end

function M:_remove_exiting_item(item)
  for index = #self._exiting_items, 1, -1 do
    if self._exiting_items[index] == item then
      table.remove(self._exiting_items, index)
      return
    end
  end
end

function M:_finish_exit(item)
  if item == nil or self._exiting_items == nil then
    return
  end
  local old_positions = self:_capture_item_positions()
  local old_height = 0
  if not is_null(self._scroll_rect) and not is_null(self._scroll_rect.content) then
    old_height = self._scroll_rect.content.sizeDelta.y
  end
  self:_remove_exiting_item(item)
  item:reset()
  if item.is_active then
    item:set_active(false, true)
  end
  table.insert(self._item_cache, item)
  self:_refresh_list_active()
  if self:_should_visual_active() and next(old_positions) ~= nil then
    self:_start_slides(old_positions, {}, old_height)
  end
end

function M:_begin_exit(item)
  self:_ensure_list_visible()
  table.insert(self._exiting_items, item)
  local binder = item.binder
  if item._has_binder and not is_null(binder) then
    binder:PlayExitAnim(function()
      self:_finish_exit(item)
    end)
    return
  end
  item:set_active(false)
  self:_finish_exit(item)
end

function M:_acquire_item()
  self:_ensure_list_visible()
  local item = table.remove(self._item_cache)
  if item then
    item:set_active(true)
    return item
  end
  local trans = self._list:AddItem(0, true)
  if is_null(trans) then
    return nil
  end
  item = self:add_panel(item_cls, trans)
  item:set_active(true)
  return item
end

function M:_recycle_item(item)
  self:_begin_exit(item)
end

function M:_apply_layout(max_count)
  if self._max_count == max_count then
    return
  end
  self._max_count = max_count
  self.rect_trans.anchorMin = Vector2(1, 1)
  self.rect_trans.anchorMax = Vector2(1, 1)
  self.rect_trans.pivot = Vector2(1, 0)
  if max_count <= 2 then
    self.rect_trans.anchoredPosition = Vector2(-117, -412)
    self.rect_trans.sizeDelta = Vector2(454, 237)
  else
    self.rect_trans.anchoredPosition = Vector2(0, -497)
    self.rect_trans.sizeDelta = Vector2(454, 348)
  end
end

function M:on_edge_bubble_data_changed(records, max_count)
  if not self.is_active then
    return
  end
  self:_apply_layout(max_count or 4)
  if 0 < #records or next(self._active_items) ~= nil or 0 < #self._exiting_items then
    self:_ensure_list_visible()
  end
  local old_positions = self:_capture_item_positions()
  local old_height = 0
  if not is_null(self._scroll_rect) and not is_null(self._scroll_rect.content) then
    old_height = self._scroll_rect.content.sizeDelta.y
  end
  local target_guids = {}
  local signature_parts = {}
  for _, record in ipairs(records) do
    target_guids[record.key] = true
    table.insert(signature_parts, record.key)
  end
  for key, item in pairs(self._active_items) do
    if not target_guids[key] then
      self._active_items[key] = nil
      self:_recycle_item(item)
    end
  end
  local new_items = {}
  for _, record in ipairs(records) do
    local item = self._active_items[record.key]
    if not item then
      item = self:_acquire_item()
      if item then
        self._active_items[record.key] = item
        new_items[item] = true
        item.trans:SetAsLastSibling()
      end
    end
    if item then
      item:refresh(record)
    end
  end
  self:_refresh_list_active()
  local has_new_item = next(new_items) ~= nil
  if self:_should_visual_active() and next(old_positions) ~= nil and has_new_item then
    self:_start_slides(old_positions, new_items, old_height)
  elseif not self._has_edge_bubble then
    self:_stop_slides()
  end
  local signature = table.concat(signature_parts, ",")
  if signature ~= self._order_signature then
    self._order_signature = signature
    if self._has_edge_bubble then
      self:_scroll_to_bottom()
    end
  end
end

function M:_scroll_to_bottom()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if not (self.is_active and self._has_edge_bubble) or is_null(self._scroll_rect) then
      return
    end
    local content = self._scroll_rect.content
    if is_null(content) or not content.gameObject.activeInHierarchy then
      return
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(content)
    self._scroll_rect.verticalNormalizedPosition = 0
    self._scroll_rect:StopMovement()
    Canvas.ForceUpdateCanvases()
    for _, slide in ipairs(self._slides) do
      apply_slide(slide)
    end
  end)
end

function M:_capture_item_positions()
  local positions = {}
  self:_for_each_visual_item(function(item)
    if not is_null(item.rect_trans) then
      positions[item] = item.rect_trans.position.y
    end
  end)
  return positions
end

function M:_stop_slides()
  for _, slide in ipairs(self._slides) do
    if not is_null(slide.rect_trans) then
      slide.rect_trans.anchoredPosition = Vector2(slide.target_x, slide.target_y)
    end
  end
  table.clear(self._slides)
end

function M:_start_slides(old_positions, new_items, old_height)
  table.clear(self._slides)
  new_items = new_items or {}
  if is_null(self._scroll_rect) then
    return
  end
  local content = self._scroll_rect.content
  if is_null(content) or not content.gameObject.activeInHierarchy then
    return
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(content)
  Canvas.ForceUpdateCanvases()
  local scale = content.lossyScale.y
  if scale <= 0 then
    return
  end
  for _, item in pairs(self._active_items) do
    local rect_trans = item.rect_trans
    if not is_null(rect_trans) and not new_items[item] then
      local target = rect_trans.anchoredPosition
      local offset = 0
      if old_positions[item] then
        offset = (old_positions[item] - rect_trans.position.y) / scale
      end
      if math.abs(offset) > slide_epsilon then
        local slide = {
          rect_trans = rect_trans,
          target_x = target.x,
          target_y = target.y,
          offset = offset,
          elapsed = 0
        }
        apply_slide(slide)
        table.insert(self._slides, slide)
      end
    end
  end
  for _, item in ipairs(self._exiting_items) do
    local rect_trans = item.rect_trans
    if not is_null(rect_trans) and old_positions[item] then
      local target = rect_trans.anchoredPosition
      local offset = (old_positions[item] - rect_trans.position.y) / scale
      if math.abs(offset) > slide_epsilon then
        local slide = {
          rect_trans = rect_trans,
          target_x = target.x,
          target_y = target.y,
          offset = offset,
          elapsed = 0
        }
        apply_slide(slide)
        table.insert(self._slides, slide)
      end
    end
  end
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  for index = #self._slides, 1, -1 do
    local slide = self._slides[index]
    slide.elapsed = slide.elapsed + deltaTime
    if not apply_slide(slide) then
      table.remove(self._slides, index)
    end
  end
end

function M:set_occluded(is_occluded)
  self._is_occluded = is_occluded
  if self:_should_visual_active() then
    self._state:SetState(is_occluded and 1 or 0)
  end
end

local function is_rect_overlapped(left, right)
  if is_null(left) or is_null(right) then
    return false
  end
  local left_corners = CsUIUtil.GetWorldCorners(left)
  local right_corners = CsUIUtil.GetWorldCorners(right)
  if left_corners.Count ~= 4 or right_corners.Count ~= 4 then
    return false
  end
  return left_corners[0].x < right_corners[2].x and left_corners[2].x > right_corners[0].x and left_corners[0].y < right_corners[2].y and left_corners[2].y > right_corners[0].y
end

function M:is_overlapping(rect_trans)
  local overlapped = false
  self:_for_each_visual_item(function(item)
    if not overlapped and item.is_active and is_rect_overlapped(item.rect_trans, rect_trans) then
      overlapped = true
    end
  end)
  return overlapped
end

function M:has_active_items()
  return next(self._active_items) ~= nil or #self._exiting_items > 0
end

return M
