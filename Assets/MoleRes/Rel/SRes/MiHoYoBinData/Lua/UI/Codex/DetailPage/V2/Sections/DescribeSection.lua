local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("DescribeSection", base_path)

function M:should_show(item_data)
  if not item_data.IsUnlocked then
    if item_data.Type == CodexDataType.Food then
      local strategy = codex_module:get_type_view_strategy(item_data.Type)
      local unlock_state = strategy:get_food_unlock_state(item_data)
      if unlock_state < strategy.FoodUnlockState.PartialUnlocked then
        return false
      end
    elseif item_data.Type ~= CodexDataType.Cloth and item_data.Type ~= CodexDataType.Furniture then
      return false
    end
  end
  local desc = item_data.ItemCfg.itemdescribe
  return desc and desc ~= ""
end

function M:refresh(item_data)
  UIUtil.set_text(self._txt_describe, item_data.ItemCfg.itemdescribe)
end

return M
