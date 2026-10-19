local M = G.Class("RecipeSectionView", G.UIPanel)
local base = G.UIPanel
local ITEM_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/RecipeItemView"
local TWOTAB_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/RecipeItemTwotabView"
local MAX_SLOT_COUNT = 4
local SLOT_SPACING = 12

function M:on_create()
  base.on_create(self)
  self._content_parent = not_null(self._trans_content) and self._trans_content or not_null(self._trans_item) and self._trans_item.parent or nil
  self._primary_views = {
    item = self:_find_primary_view(self._trans_item, ITEM_VIEW_PATH),
    onetab = self:_find_primary_view(self._trans_item_onetab, ITEM_VIEW_PATH),
    twotab = self:_find_primary_view(self._trans_item_two_tab, TWOTAB_VIEW_PATH)
  }
  self._extra_slots = {}
  self:_hide_all()
  self._active_type = nil
  self._on_click_callback = nil
end

function M:_find_primary_view(parent_trans, view_path)
  if is_null(parent_trans) then
    return nil
  end
  for i = 0, parent_trans.childCount - 1 do
    local child = parent_trans:GetChild(i)
    if not_null(child:GetComponent(typeof(MonoViewBinder))) then
      return self:add_panel(view_path, child)
    end
  end
  return self:add_panel(view_path, parent_trans)
end

function M:set_visible(visible)
  UIUtil.set_active(self.trans, visible)
end

function M:set_on_click(callback)
  self._on_click_callback = callback
end

function M:refresh(info, load_proxy)
  self:hide_tooltip()
  if not_null(self._txt_cookware_title) then
    UIUtil.set_text(self._txt_cookware_title, info.title or "")
  end
  local locked = info.locked
  local items = info.items or {}
  if #items == 0 then
    self:_hide_all()
    return
  end
  self:_hide_all()
  local count = math.min(#items, MAX_SLOT_COUNT)
  local used_primary = {}
  local active_slots = {}
  for i = 1, count do
    local mat = items[i]
    local tpl_type = mat.template_type or "item"
    local view_path = tpl_type == "twotab" and TWOTAB_VIEW_PATH or ITEM_VIEW_PATH
    local template_trans = self:_get_template(tpl_type)
    if not used_primary[tpl_type] and not_null(template_trans) then
      used_primary[tpl_type] = true
      local pv = self._primary_views[tpl_type] or self._primary_views.item
      if pv then
        UIUtil.set_active(template_trans, true)
        UIUtil.set_active(pv.trans, true)
        self:_fill_slot(tpl_type, pv, mat, i, load_proxy)
        table.insert(active_slots, {trans = template_trans})
      end
    elseif not_null(template_trans) then
      local slot = self:_get_or_create_extra_slot(i, template_trans, view_path)
      UIUtil.set_active(slot.go, true)
      UIUtil.set_active(slot.view.trans, true)
      self:_fill_slot(tpl_type, slot.view, mat, i, load_proxy)
      table.insert(active_slots, {
        trans = slot.trans
      })
    end
  end
  self:_layout_slots(active_slots)
  self:_apply_lock_state(locked)
end

function M:_get_template(tpl_type)
  if tpl_type == "twotab" then
    return self._trans_item_two_tab
  end
  if tpl_type == "onetab" then
    return self._trans_item_onetab
  end
  return self._trans_item
end

function M:_get_or_create_extra_slot(index, template_trans, view_path)
  local key = template_trans:GetInstanceID() .. "_" .. index
  if self._extra_slots[key] then
    return self._extra_slots[key]
  end
  local clone = CS.UnityEngine.Object.Instantiate(template_trans.gameObject, self._content_parent)
  local clone_trans = clone.transform
  local view
  for i = 0, clone_trans.childCount - 1 do
    local child = clone_trans:GetChild(i)
    if not_null(child:GetComponent(typeof(MonoViewBinder))) then
      view = self:add_panel(view_path, child)
      break
    end
  end
  view = view or self:add_panel(view_path, clone_trans)
  local slot = {
    go = clone,
    trans = clone_trans,
    view = view
  }
  self._extra_slots[key] = slot
  return slot
end

function M:_hide_extra_slots()
  for _, slot in pairs(self._extra_slots) do
    UIUtil.set_active(slot.go, false)
  end
end

function M:_layout_slots(slots)
  if #slots <= 1 then
    return
  end
  local anchor_y = slots[1].trans.anchoredPosition.y
  local x = 0
  for _, s in ipairs(slots) do
    local rt = s.trans
    local w = rt.rect.width
    if w <= 0 then
      w = 100
    end
    rt.anchoredPosition = Vector2(x + w * 0.5, anchor_y)
    x = x + w + SLOT_SPACING
  end
end

function M:_get_views(tpl_type)
  return {}
end

function M:_hide_all()
  self:_hide_extra_slots()
  for _, view in pairs(self._primary_views) do
    if view then
      UIUtil.set_active(view.trans, false)
    end
  end
  UIUtil.set_active(self._trans_item, false)
  UIUtil.set_active(self._trans_item_onetab, false)
  UIUtil.set_active(self._trans_item_two_tab, false)
  self._active_type = nil
end

function M:_show_type(_)
end

function M:_fill_slot(tpl_type, view, mat, item_index, load_proxy)
  if tpl_type == "twotab" then
    local tags = mat.tags or {}
    local icon1 = tags[1] and tags[1].icon or ""
    local icon2 = tags[2] and tags[2].icon or ""
    view:refresh(icon1, icon2, mat.locked, load_proxy)
    if not mat.locked then
      view:set_click_params(item_index, pack(self, M._on_item_click))
    end
  elseif tpl_type == "onetab" then
    local tags = mat.tags or {}
    local icon = tags[1] and tags[1].icon or ""
    view:refresh(icon, mat.locked, load_proxy)
    if not mat.locked then
      view:set_click_params(item_index, 1, pack(self, M._on_item_click))
    end
  else
    view:refresh(mat.icon, mat.locked, load_proxy)
    if not mat.locked then
      view:set_click_params(item_index, 1, pack(self, M._on_item_click))
    end
  end
end

function M:_on_item_click(item_index, tag_index, anchor_trans)
  if self._on_click_callback then
    self._on_click_callback(item_index, tag_index, anchor_trans)
  end
end

function M:show_tooltip(text, anchor_trans)
  if not_null(self._trans_icon_tips) then
    if not_null(self._txt_desc) then
      UIUtil.set_text(self._txt_desc, text or "")
    end
    if not_null(anchor_trans) then
      local tips_parent = self._trans_icon_tips.parent or self.trans
      local local_pos = tips_parent:InverseTransformPoint(anchor_trans.position)
      local tips_h = self._trans_icon_tips.rect.height
      self._trans_icon_tips.localPosition = Vector3(local_pos.x, local_pos.y + tips_h * 0.5 + 10, 0)
    end
    UIUtil.set_active(self._trans_icon_tips, true)
  end
end

function M:hide_tooltip()
  if not_null(self._trans_icon_tips) then
    UIUtil.set_active(self._trans_icon_tips, false)
  end
end

function M:_apply_lock_state(locked)
  local sg = self._ui_state_group_lock or self._state_group_lock
  if not_null(sg) then
    sg:SetState(locked and 0 or 1)
  end
end

return M
