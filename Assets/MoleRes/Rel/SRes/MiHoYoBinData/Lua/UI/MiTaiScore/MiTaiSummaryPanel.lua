local M = G.Class("MiTaiSummaryPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTaiScore/MiTaiSummaryPanel"
  self._summary_data = nil
  self._is_finishing = false
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close, pack(self, M.finish_flow))
  self:bind_callback(self._btn_info, pack(self, M.show_suggestion))
end

function M:on_enable()
  base.on_enable(self)
  self._summary_data = self:get_extra_data() or {}
  self._selected_room_index = self._summary_data.selected_index or 1
  self._is_finishing = false
  self:_refresh_level_progress()
  self:_refresh_summary_states()
  UIUtil.set_text(self._txt_rating_num, TextMapFormatUtil.FormatInteger(self._summary_data.total_score or 0))
  UIUtil.set_text(self._txt_dialog, self._summary_data.total_evaluation or "")
end

function M:_refresh_level_progress()
  local evaluate_data = self._summary_data.evaluate_data or {}
  local score = evaluate_data.new_max_score or self._summary_data.total_score or 0
  local level_cfg = mi_tai_score_module:get_score_level_cfg(score)
  local next_level_cfg = mi_tai_score_module:get_score_next_level_cfg(score)
  local is_max_level = level_cfg ~= nil and next_level_cfg ~= nil and level_cfg.level == next_level_cfg.level
  local is_new_gear = (evaluate_data.new_level or 0) > (evaluate_data.last_level or 0)
  UIUtil.set_text(self._txt_title, level_cfg and level_cfg.des or "")
  self._ui_state_group_max_level:SetState(is_max_level and 1 or 0)
  self._ui_state_group_gearNew:SetState(is_new_gear and 1 or 0)
  if not is_max_level then
    UIUtil.set_text(self._txt_now_grade, string.format("%s/%s", TextMapFormatUtil.FormatInteger(score), TextMapFormatUtil.FormatInteger(next_level_cfg and next_level_cfg.score or score)))
  end
  UIUtil.set_text(self._txt_grad, TextMapFormatUtil.FormatInteger(level_cfg.level or 0))
end

function M:_refresh_summary_states()
  local evaluate_data = self._summary_data.evaluate_data or {}
  local reward_list = evaluate_data.reward_list or {}
  local room_list = self._summary_data.room_list or {}
  local unlock_order_count = 0
  local unlock_garland = 0
  for _, cfg in ipairs(reward_list) do
    if cfg.houseserverid ~= 0 then
      unlock_order_count = unlock_order_count + 1
    end
    if cfg.garland_id ~= 0 then
      unlock_garland = cfg.garland_id
    end
  end
  self._ui_state_group_award:SetState(0 < unlock_garland and 0 or 1)
  self._ui_state_group_unlock_orders:SetState(0 < unlock_order_count and 0 or 1)
  self._ui_state_group_check_details:SetState(2 <= #room_list and 0 or 1)
  if 0 < unlock_order_count then
    UIUtil.set_text_by_id(self._txt_unlock_orders, "MitaiScore_Tip_NewOrder")
  end
  UIUtil.set_text_by_id(self._txt_rating_title, 2 <= #room_list and "MitaiScore_ScoreTitle_MoreRoom" or "MitaiScore_ScoreTitle_OneRoom")
  if 0 < unlock_garland then
    self:_refresh_rewards({unlock_garland})
  end
end

function M:_refresh_rewards(reward_list)
  for index, item_id in ipairs(reward_list) do
    local item = self._reward_items[index]
    if item == nil then
      local trans = index == 1 and self._list_award:GetItem(0) or self._list_award:AddItem(0, true)
      item = self:add_panel(item_module.item_v2_panel_cls_name, trans)
      self._reward_items[index] = item
    end
    item:set_item_data(item_id, nil)
    item:bind_item_info_btn(item_id)
    item:set_active(true)
  end
  for index = #reward_list + 1, #self._reward_items do
    self._reward_items[index]:set_active(false)
  end
end

function M:select_room(index)
  self._selected_room_index = index
end

function M:show_suggestion(index)
  if type(index) ~= "number" then
    index = nil
  end
  local rooms = self._summary_data.room_list or self._summary_data.rooms or {}
  if #rooms == 0 then
    return
  end
  self.holder:show_suggestion({
    rooms = rooms,
    selected_index = index or self._selected_room_index or 1
  })
end

function M:finish_flow()
  if self._is_finishing then
    return
  end
  self._is_finishing = true
  self.holder:finish_flow()
end

return M
