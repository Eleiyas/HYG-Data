local M = G.Class("NpcClothMachineCategoryPanel", G.UIPanel)
local base = G.UIPanel
local CATEGORY_ITEM_CLS = "UI/NpcCloth/NpcClothMachineCategoryItem"

function M:init()
  base.init(self)
  self._categories = {}
  self._context = {}
  self._category_items = {}
  self._is_scroller_init = false
  self._category_count = 0
end

function M:refresh(categories, context, reset_position, force_reinit)
  self._categories = categories or {}
  self._context = context or self._context or {}
  if force_reinit == true then
    self._is_scroller_init = false
    self._category_count = 0
  end
  self:_refresh_category_items(reset_position == true)
end

function M:set_current_category(category_id, focus_item)
  self._context = self._context or {}
  if self._context.current_category_id == category_id then
    return
  end
  self._context.current_category_id = category_id
  self:_refresh_category_items(false)
  if focus_item == true then
    self:_ensure_category_visible(category_id)
  end
end

function M:_refresh_category_items(reset_position)
  if is_null(self._scroll_tab_bar) then
    return
  end
  local count = #(self._categories or {})
  if not self._is_scroller_init then
    self._category_items = {}
    self._scroll_tab_bar:Init(pack(self, M._refresh_category_item), count)
    self._is_scroller_init = true
    self._category_count = count
    return
  end
  if self._category_count ~= count then
    self._scroll_tab_bar:ReLoad(pack(self, M._refresh_category_item), count)
    self._category_count = count
  else
    self._scroll_tab_bar:RefreshCurrent()
  end
  if reset_position then
    self._scroll_tab_bar:MoveTo(0)
  end
end

function M:_refresh_category_item(trans, index)
  local category = self._categories[index + 1]
  local instance_id = trans:GetInstanceID()
  local item = self._category_items[instance_id]
  if not item then
    item = self:add_panel(CATEGORY_ITEM_CLS, trans)
    self._category_items[instance_id] = item
  end
  item:refresh(category, {
    current_category_id = self._context.current_category_id,
    on_click_category = pack(self, M._on_click_category)
  })
end

function M:_on_click_category(category_id, category)
  if category and category.interactable == false then
    self:_refresh_category_items(false)
    return
  end
  self:set_current_category(category_id, false)
  if self._context and self._context.on_click_category then
    self._context.on_click_category(category_id, category)
  end
end

function M:_ensure_category_visible(category_id)
  if is_null(self._scroll_tab_bar) then
    return
  end
  local category_index = self:_get_category_index(category_id)
  if category_index then
    self._scroll_tab_bar:EnsureItemVisible(category_index - 1)
  end
end

function M:_get_category_index(category_id)
  for index, category in ipairs(self._categories or {}) do
    if category.category_id == category_id then
      return index
    end
  end
  return nil
end

return M
