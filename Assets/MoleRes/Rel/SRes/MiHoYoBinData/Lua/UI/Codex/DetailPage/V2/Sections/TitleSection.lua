local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("TitleSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
end

function M:set_sequence(sequence)
  self._display_sequence = sequence
  local has_num = sequence and 0 < sequence
  self._trans_tag_num_quality.gameObject:SetActive(has_num)
  if has_num then
    UIUtil.set_text(self._txt_num, string.format("%03d", sequence))
  end
end

function M:refresh(item_data)
  local is_package = codex_module:is_package_sub_type(item_data.SubType)
  local has_num = not is_package and item_data.Type ~= CodexDataType.Furniture and item_data.Type ~= CodexDataType.Cloth and self._display_sequence and self._display_sequence > 0
  self._trans_tag_num_quality.gameObject:SetActive(has_num)
  local show_quality = true
  local show_name = item_data.IdCfg.name
  local food_strategy, food_unlock_state
  if item_data.Type == CodexDataType.Food then
    food_strategy = codex_module:get_type_view_strategy(item_data.Type)
    food_unlock_state = food_strategy:get_food_unlock_state(item_data)
    if food_unlock_state == food_strategy.FoodUnlockState.Unknown then
      show_quality = false
      show_name = codex_module.default_lock_info
    end
  elseif not item_data.IsUnlocked then
    local always_show_quality = item_data.Type == CodexDataType.Plant or item_data.Type == CodexDataType.Food or item_data.Type == CodexDataType.Furniture or item_data.Type == CodexDataType.Cloth
    if not always_show_quality then
      show_quality = false
    end
    if item_data.Type ~= CodexDataType.Furniture and item_data.Type ~= CodexDataType.Cloth then
      show_name = codex_module.default_lock_info
    end
  end
  UIUtil.set_active(self._trans_quality, show_quality)
  UIUtil.set_active(self._trans_tag_group, has_num)
  if show_quality then
    local rank = not_null(item_data.ItemCfg) and item_data.ItemCfg.rank or 0
    self._ui_state_group_quality_no_id:SetState(rank)
  end
  if has_num then
    UIUtil.set_text(self._txt_num, string.format("%03d", self._display_sequence))
  end
  UIUtil.set_text(self._txt_title, show_name)
  self:_refresh_food_tag(item_data, food_strategy, food_unlock_state)
  self:_refresh_npc_icon(item_data, food_strategy, food_unlock_state)
  local points = not is_package and (item_data.CodexCfg and item_data.CodexCfg.totalscorepoints or 0) or 0
  if not item_data.IsUnlocked then
    points = 0
  elseif food_strategy and food_unlock_state and food_unlock_state < food_strategy.FoodUnlockState.Cooked then
    points = 0
  end
  self._trans_collection_points.gameObject:SetActive(0 < points)
  if 0 < points then
    UIUtil.set_text_by_id(self._txt_collection_points, "Codex_Detail_AddScore", points)
  end
end

function M:_refresh_food_tag(item_data, food_strategy, food_unlock_state)
  if is_null(self._trans_tag_legendary) then
    return
  end
  local show = false
  if food_strategy and food_strategy:should_show_recipe_info(item_data) then
    local cat_name = food_strategy:get_food_category_name(item_data)
    if cat_name then
      show = true
      UIUtil.set_text(self._txt_legend, cat_name)
      if not_null(self._ui_state_group_quality_legend) then
        local rank = not_null(item_data.ItemCfg) and item_data.ItemCfg.rank or 0
        self._ui_state_group_quality_legend:SetState(rank)
      end
    end
  end
  UIUtil.set_active(self._trans_tag_legendary, show)
end

function M:_refresh_npc_icon(item_data, food_strategy, food_unlock_state)
  if is_null(self._img_npc_icon) then
    return
  end
  local show = false
  if food_strategy and food_strategy:should_show_recipe_info(item_data) then
    local npc_id = food_strategy:get_secret_recipe_npc_id(item_data) or 0
    show = 0 < npc_id
    if show then
      npc_module:set_npc_icon_by_id(self._img_npc_icon, npc_id, self:get_load_proxy())
    end
  end
  UIUtil.set_active(self._img_npc_icon, show)
end

return M
