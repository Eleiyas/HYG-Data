local M = G.Class("GeLianFoodMarketPriceDialog", G.UIWindow)
local base = G.UIWindow
local price_item_cls = "UI/GeLianMarket/GeLianMarketPriceDialogItem"
local PosState = {
  LeftTop = 0,
  LeftBottom = 1,
  RightTop = 2,
  RightBottom = 3
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GeLianFoodMarket/GeLianFoodMarketPriceDialog"
  self.config.type = EUIType.Dialog
  self._price_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_background)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
  self:_reset_position()
  self:_refresh_pos_state()
end

function M:on_destroy()
  self._price_items = {}
  base.on_destroy(self)
end

function M:_refresh_view()
  local view_data = self:get_extra_data()
  if view_data == nil then
    return
  end
  UIUtil.set_text_by_id(self._txt_cycle, "Market_Crop_GrowthTime", self:_get_growth_days(view_data.tag))
  local price_items = self:_build_price_items(view_data.fruit_ids, view_data.price_multiplier)
  self:_ensure_price_items(#price_items)
  for i = 1, #self._price_items do
    self._price_items[i]:render(price_items[i])
  end
end

function M:_build_price_items(fruit_ids, price_multiplier)
  local items = {}
  for i = 1, #(fruit_ids or {}) do
    local config_id = fruit_ids[i]
    items[i] = {
      config_id = config_id,
      price = CsGeLianMarketModuleUtil.CalculatePriceByMultiplier(config_id, price_multiplier or 100)
    }
  end
  return items
end

function M:_ensure_price_items(count)
  for i = #self._price_items + 1, count do
    local trans
    if i == 1 then
      trans = self._trans_price_item
    else
      trans = self._list_item_binder_price:AddItem(0, true)
    end
    if is_null(trans) then
      return
    end
    self._price_items[i] = self:add_panel(price_item_cls, trans)
  end
end

function M:_get_growth_days(crop_tag)
  if not string.is_valid(crop_tag) then
    return 0
  end
  local plant_cfg_table = ExcelDataUtil.get_table(typeof(BCropPlantCfg)) or {}
  for _, plant_cfg in pairs(plant_cfg_table) do
    if plant_cfg.name == crop_tag then
      return plant_cfg.stageseedlingidlistLength or 0
    end
  end
  return 0
end

function M:_reset_position()
  local view_data = self:get_extra_data()
  if view_data == nil or view_data.target_screen_x == nil or view_data.target_screen_y == nil then
    return
  end
  local success, local_point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._trans_node.parent, Vector2(view_data.target_screen_x, view_data.target_screen_y), UIManagerInstance.ui_camera)
  if success then
    self._trans_node.anchoredPosition = local_point
  end
end

function M:_refresh_pos_state()
  if is_null(self._state_group_pos) or is_null(self._trans_dialog_body) then
    return
  end
  local view_data = self:get_extra_data()
  local is_right_side = view_data ~= nil and view_data.is_right_side == true
  local state = is_right_side and PosState.RightTop or PosState.LeftTop
  self._state_group_pos:SetState(state)
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_dialog_body)
  local body = self._trans_dialog_body
  local bottom_local_y = self._trans_node.anchoredPosition.y + body.anchoredPosition.y - body.pivot.y * body.rect.height
  if bottom_local_y < self.rect_trans.rect.yMin then
    self._state_group_pos:SetState(state + 1)
  end
end

return M
