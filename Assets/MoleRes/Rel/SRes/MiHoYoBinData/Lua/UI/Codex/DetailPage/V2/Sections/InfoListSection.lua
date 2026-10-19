local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("InfoListSection", base_path)
local base = G.DetailSectionBase
local INFO_TYPE = {
  TEXT = "text",
  COOKWARE = "cookware",
  RECIPE = "recipe",
  PRODUCE = "produce"
}
M.INFO_TYPE = INFO_TYPE
local INFO_ITEM_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/InfoItemView"
local COOKWARE_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/CookWareItemView"
local RECIPE_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/RecipeSectionView"
local PRODUCE_VIEW_PATH = "UI/Codex/DetailPage/V2/Sections/CookProduceItemView"

function M:on_create()
  base.on_create(self)
  self._text_panels = {}
  self._text_list_parent = self._trans_item_info.parent
  self._trans_item_info.gameObject:SetActive(false)
  self._cookware_view = self:add_panel(COOKWARE_VIEW_PATH, self._trans_item_cook_ware)
  self._cookware_view:set_visible(false)
  self._recipe_view = self:add_panel(RECIPE_VIEW_PATH, self._trans_item_cook_recipe)
  self._recipe_view:set_visible(false)
  self._recipe_view:set_on_click(function(item_index, tag_index, anchor_trans)
    self:_on_recipe_click(item_index, tag_index, anchor_trans)
  end)
  if not_null(self._trans_item_cook_produce) then
    self._produce_view = self:add_panel(PRODUCE_VIEW_PATH, self._trans_item_cook_produce)
    self._produce_view:set_visible(false)
  end
  self._current_recipe_data = nil
  self._active_tooltip_key = nil
end

function M:should_show(item_data)
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local info_list = strategy.get_detail_info_list and strategy:get_detail_info_list(item_data)
  return info_list and 0 < #info_list
end

function M:refresh(item_data)
  self:_close_tooltip()
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local info_list = strategy:get_detail_info_list(item_data)
  local load_proxy = self:get_load_proxy()
  local text_index = 0
  local show_cookware = false
  local show_recipe = false
  local show_produce = false
  for _, info in ipairs(info_list) do
    if info.type == INFO_TYPE.TEXT then
      text_index = text_index + 1
      local panel = self:_get_or_create_text(text_index)
      panel:set_active(true)
      panel:refresh_info(info.title, info.value)
    elseif info.type == INFO_TYPE.COOKWARE then
      show_cookware = true
      self._cookware_view:refresh(info, load_proxy)
    elseif info.type == INFO_TYPE.RECIPE then
      show_recipe = true
      self._current_recipe_data = info
      self._recipe_view:refresh(info, load_proxy)
    elseif info.type == INFO_TYPE.PRODUCE then
      show_produce = true
      if self._produce_view then
        self._produce_view:refresh(info, load_proxy)
      end
    end
  end
  for i = text_index + 1, #self._text_panels do
    self._text_panels[i]:set_active(false)
  end
  self._cookware_view:set_visible(show_cookware)
  self._recipe_view:set_visible(show_recipe)
  if self._produce_view then
    self._produce_view:set_visible(show_produce)
  end
end

function M:_get_or_create_text(index)
  if self._text_panels[index] then
    return self._text_panels[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item_info.gameObject, self._text_list_parent)
  go.transform:SetSiblingIndex(index)
  local panel = self:add_panel(INFO_ITEM_VIEW_PATH, go.transform)
  self._text_panels[index] = panel
  return panel
end

function M:_on_recipe_click(item_index, tag_index, anchor_trans)
  local info = self._current_recipe_data
  if not info then
    return
  end
  local items = info.items or {}
  local mat = items[item_index]
  if not mat or mat.locked then
    return
  end
  local key = string.format("%d_%d", item_index, tag_index or 1)
  if self._active_tooltip_key == key then
    self:_close_tooltip()
    return
  end
  self:_close_tooltip()
  self._active_tooltip_key = key
  local tag_name = ""
  local tpl_type = mat.template_type or "item"
  if tpl_type == "twotab" then
    local tags = mat.tags or {}
    tag_name = tags[tag_index] and tags[tag_index].name or ""
  elseif tpl_type == "onetab" then
    local tags = mat.tags or {}
    tag_name = tags[1] and tags[1].name or ""
  else
    tag_name = mat.tag_name or ""
    if not string.is_valid(tag_name) and mat.id and mat.id > 0 then
      local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), mat.id)
      if not_null(item_cfg) then
        tag_name = item_cfg.name
      end
    end
  end
  if not string.is_valid(tag_name) then
    return
  end
  self._recipe_view:show_tooltip(tag_name, anchor_trans)
  if self._tooltip_blocker_cb then
    self._tooltip_blocker_cb(true)
  end
end

function M:_close_tooltip()
  self._active_tooltip_key = nil
  if self._recipe_view then
    self._recipe_view:hide_tooltip()
  end
  if self._tooltip_blocker_cb then
    self._tooltip_blocker_cb(false)
  end
end

return M
