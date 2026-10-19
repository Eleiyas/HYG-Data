local M = G.Class("HairDyeingFlowerExchangePage", G.UIWindow)
local base = G.UIWindow
local bag_panel_cls = "UI/HairDyeing/HairDyeingFlowerExchangeBagPanel"
local flower_detail_panel_cls = "UI/HairDyeing/HairDyeingFlowerDetailPanel"
local default_exchange_id = 1
local flower_stack_size_panel_stub = {
  change_state = function()
  end,
  show = function()
  end,
  refresh_select_stack_ui = function()
  end
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/HairDyeing/HairDyeingNPCExchangePage"
  self.config.type = EUIType.Page
  self.common_bag_panel = nil
  self._flower_detail_panel = nil
  self._stack_num_panel = nil
  self._stack_num_panel_ready = false
  self._selected_counts = {}
  self._selected_detail_guid = nil
  self._selected_detail_data = nil
  self._exchange_id = default_exchange_id
  self._consume_ranks = {}
  self._required_flower_count = 0
  self._remaining_exchange_count = 0
  self._max_exchange_count = 0
  self._reward_item_id = 0
  self._reward_item_count = 0
  self._on_exchange_success = nil
  self._is_requesting = false
  self._config_ready = false
  self._ignore_detail_num_callback = false
  self.is_need_lock_other_item = false
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange))
  if not is_null(self._trans_flower_detail) then
    self._flower_detail_panel = self:add_panel(flower_detail_panel_cls, self._trans_flower_detail)
    self._flower_detail_panel:refresh(nil)
  end
  if not is_null(self._trans_lite_common_bag) then
    self.common_bag_panel = self:add_panel(bag_panel_cls, self._trans_lite_common_bag)
    self.common_bag_panel:set_extra_data(back_bag_module.bag_main_type.normal)
    self.common_bag_panel:set_cur_item_select_type(back_bag_module.packet_item_select_type.num_multi_selected)
    self.common_bag_panel:refresh_data(back_bag_module.bag_show_type.hair_dye_flower)
  end
  if self._stack_num_panel then
    self:_bind_stack_num_panel_ready_callback()
  end
end

function M:_bind_stack_num_panel_ready_callback()
  local stack_num_panel = self._stack_num_panel
  if stack_num_panel == nil then
    return
  end
  
  local function on_stack_num_panel_ready(loaded_stack_num_panel)
    if self._stack_num_panel ~= loaded_stack_num_panel then
      return
    end
    loaded_stack_num_panel._stack_select_size_panel = flower_stack_size_panel_stub
    self._stack_num_panel_ready = true
    self:_refresh_selected_detail()
  end
  
  if not_null(stack_num_panel._slider) and not_null(stack_num_panel._stack_select_size_panel) then
    on_stack_num_panel_ready(stack_num_panel)
  else
    stack_num_panel._add_panel_cb = on_stack_num_panel_ready
  end
end

function M:_is_stack_num_panel_ready()
  local stack_num_panel = self._stack_num_panel
  return self._stack_num_panel_ready and stack_num_panel ~= nil and not_null(stack_num_panel.game_obj) and not_null(stack_num_panel._slider)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:on_enable()
  base.on_enable(self)
  self._is_requesting = false
  self:_refresh_entry_data()
  self:_setup_bag()
  self:_clear_selection()
  self:_refresh_static_texts()
  self:_refresh_remaining_count()
  self:_refresh_exchange_state()
end

function M:on_destroy()
  self.common_bag_panel = nil
  self._flower_detail_panel = nil
  self._stack_num_panel = nil
  self._stack_num_panel_ready = false
  self._selected_detail_data = nil
  self._on_exchange_success = nil
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.update_bag_item_selected_num, function(server_data)
    self:_on_selected_num_changed(server_data)
  end)
  self:add_evt_listener(EventID.LuaChangePacket, function()
    if not is_null(self.common_bag_panel) then
      self.common_bag_panel:refresh_bag()
    end
    self:_refresh_selection_after_inventory_change()
  end)
  self:add_evt_listener(EventID.LuaHairDyeRabbitExchangeResult, pack(self, M._on_exchange_result))
  self:add_evt_listener(EventID.LuaHairDyeRabbitExchangeInfoChanged, pack(self, M._on_exchange_info_changed))
end

function M:_refresh_entry_data()
  local data = self:get_extra_data() or {}
  self._exchange_id = data.exchange_id or default_exchange_id
  self._on_exchange_success = data.on_exchange_success
  self:_refresh_exchange_config()
end

function M:_refresh_exchange_config()
  local config = hair_dyeing_module:get_flower_exchange_config(self._exchange_id)
  self._config_ready = config ~= nil
  if config == nil then
    self._consume_ranks = {}
    self._required_flower_count = 0
    self._remaining_exchange_count = 0
    self._max_exchange_count = 0
    self._reward_item_id = 0
    self._reward_item_count = 0
    return
  end
  self._consume_ranks = config.consume_ranks
  self._required_flower_count = config.required_flower_count
  self._remaining_exchange_count = config.remaining_exchange_count
  self._max_exchange_count = config.max_exchange_count
  self._reward_item_id = config.reward_item_id
  self._reward_item_count = config.reward_item_count
end

function M:_setup_bag()
  if is_null(self.common_bag_panel) then
    return
  end
  self.common_bag_panel:clear_all_select_item_data()
  self.common_bag_panel:set_extra_data(back_bag_module.bag_main_type.normal)
  self.common_bag_panel:set_cur_item_select_type(back_bag_module.packet_item_select_type.num_multi_selected)
  self.common_bag_panel:refresh_data(back_bag_module.bag_show_type.hair_dye_flower)
  self.common_bag_panel:set_filter_tags(nil)
  self.common_bag_panel:set_filter_ranks(self._consume_ranks)
  self.common_bag_panel:refresh_ui()
end

function M:_clear_selection()
  self._selected_counts = {}
  self._selected_detail_guid = nil
  self._selected_detail_data = nil
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel._selected_guid_by_item_id = {}
    self.common_bag_panel:clear_all_select_item_data()
    self.common_bag_panel:set_select_item_index(0)
    self.common_bag_panel:refresh_bag()
    self.common_bag_panel:refresh_title()
  end
  self:_refresh_selected_detail()
end

function M:get_required_flower_count()
  return self._required_flower_count
end

function M:get_selected_flower_count()
  local total = 0
  for _, count in pairs(self._selected_counts or {}) do
    total = total + count
  end
  return total
end

function M:is_flower_selected(item_id)
  self:_rebuild_selected_counts()
  return 0 < (self._selected_counts[item_id] or 0)
end

function M:get_fixed_select_num(server_data)
  if is_null(server_data) then
    return 0
  end
  self:_rebuild_selected_counts()
  return self._selected_counts[server_data.ConfigId] or 0
end

function M:_get_select_capacity(server_data, current_num)
  if is_null(server_data) then
    return 0
  end
  self:_rebuild_selected_counts()
  local item_id = server_data.ConfigId
  local current = self._selected_counts[item_id] or current_num or 0
  local other_selected = self:get_selected_flower_count() - current
  local remaining_capacity = math.max(0, self._required_flower_count - other_selected)
  local owned = hair_dyeing_module:get_material_num(item_id)
  return math.min(owned, remaining_capacity)
end

function M:get_max_select_item_num(server_data, current_num)
  if is_null(server_data) then
    return 0
  end
  local is_initial_select = current_num == nil or current_num <= 0
  local max_select_num = self:_get_select_capacity(server_data, current_num)
  if max_select_num <= 0 then
    if is_initial_select then
    end
    return 0
  end
  if is_initial_select then
    return 1
  end
  return math.min(current_num, max_select_num)
end

function M:subtract_select_item_num(_server_data, current_num)
  return math.max(0, (current_num or 0) - 1)
end

function M:should_show_zero_num_item_detail(_server_data)
  return true
end

function M:refresh_selected_ui(item_data)
  local server_data = item_data and item_data.server_data or nil
  self._selected_detail_guid = item_data and item_data.guid or nil
  self._selected_detail_data = server_data
  if not is_null(server_data) and self._selected_detail_guid ~= nil then
    self:_rebuild_selected_counts()
    local item_id = server_data.ConfigId
    local current = self._selected_counts[item_id] or 0
    if current <= 0 then
      local selected_total = self:get_selected_flower_count()
      local owned = hair_dyeing_module:get_material_num(item_id)
      if selected_total < self._required_flower_count and 0 < owned then
        self.common_bag_panel:change_item_num_by_guid(self._selected_detail_guid, 1)
        self:_rebuild_selected_counts()
      else
        Logger.LogWarning(string.format("[HairDyeExchange] default selection skipped. itemId=%s, owned=%s, selected=%s, required=%s, configReady=%s", tostring(item_id), tostring(owned), tostring(selected_total), tostring(self._required_flower_count), tostring(self._config_ready)))
      end
    end
  end
  self:_refresh_selected_detail()
end

function M:bag_panel_tog_change(_cur_tog_type)
end

function M:_on_selected_num_changed(server_data)
  self:_rebuild_selected_counts()
  if not is_null(server_data) and self._selected_detail_data ~= nil and server_data.ConfigId == self._selected_detail_data.ConfigId then
    self._selected_detail_data = server_data
    self._selected_detail_guid = server_data.StackGuid
  end
  self:_refresh_selection_ui()
end

function M:_rebuild_selected_counts()
  local selected_counts = {}
  if not is_null(self.common_bag_panel) then
    for _, item in ipairs(self.common_bag_panel:get_all_select_item_data() or {}) do
      local server_data = item.server_data
      if not is_null(server_data) and 0 < (item.num or 0) then
        selected_counts[server_data.ConfigId] = (selected_counts[server_data.ConfigId] or 0) + item.num
      end
    end
  end
  self._selected_counts = selected_counts
end

function M:_refresh_selection_after_inventory_change()
  self:_rebuild_selected_counts()
  for item_id, count in pairs(self._selected_counts) do
    if count > hair_dyeing_module:get_material_num(item_id) then
      self:_clear_selection()
      self:_refresh_exchange_state()
      return
    end
  end
  self:_refresh_selection_ui()
end

function M:_refresh_selection_ui()
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:refresh_title()
  end
  self:_refresh_selected_detail()
  self:_refresh_exchange_state()
end

function M:_refresh_selected_detail()
  local server_data = self._selected_detail_data
  if not is_null(self._flower_detail_panel) then
    self._flower_detail_panel:refresh({
      item_id = not is_null(server_data) and server_data.ConfigId or 0,
      server_data = server_data
    })
  end
  if is_null(server_data) then
    if self._stack_num_panel then
      local state_machine = self._stack_num_panel._state_machine
      local cur_state = state_machine and state_machine._cur_state or nil
      if cur_state == EUIState.Open or cur_state == EUIState.Show then
        self._stack_num_panel:change_state(EUIState.Hide)
      end
    end
    return
  end
  local item_id = server_data.ConfigId
  if self:_is_stack_num_panel_ready() then
    local current = self._selected_counts[item_id] or 0
    local max_num = math.max(self:_get_select_capacity(server_data, current), current)
    self._ignore_detail_num_callback = true
    self._stack_num_panel:change_state(EUIState.Show)
    self._stack_num_panel:show({
      cur_num = current,
      max_num = max_num,
      min_num = 0,
      server_data = server_data,
      is_show_price = false,
      num_change_callback = function(value)
        self:_on_detail_num_changed(value)
      end
    })
    self._ignore_detail_num_callback = false
  end
end

function M:_on_detail_num_changed(value)
  if self._ignore_detail_num_callback then
    return
  end
  if is_null(self.common_bag_panel) or self._selected_detail_guid == nil then
    return
  end
  local target = math.max(0, math.floor((value or 0) + 0.5))
  self.common_bag_panel:set_select_num_keep_focus(self._selected_detail_guid, target)
  self:_rebuild_selected_counts()
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:refresh_title()
  end
  self:_refresh_exchange_state()
end

function M:_refresh_static_texts()
  UIUtil.set_text_by_id(self._txt_title, "HairDyeing_FlowerExchange_Title")
  UIUtil.set_text_by_id(self._txt_exchange, "HairDyeing_FlowerExchange_ExchangeButton")
end

function M:_refresh_remaining_count()
  UIUtil.set_text_by_id(self._txt_remaining_count, "HairDyeing_FlowerExchange_RemainingCount", self._remaining_exchange_count, self._max_exchange_count)
end

function M:_can_exchange()
  return not self._is_requesting and self._config_ready and self._remaining_exchange_count > 0 and self:get_selected_flower_count() == self._required_flower_count
end

function M:_refresh_exchange_state()
  local can_attempt_exchange = not self._is_requesting and self._config_ready and self:get_selected_flower_count() == self._required_flower_count
  if not is_null(self._btn_exchange) then
    self._btn_exchange.interactable = can_attempt_exchange
  end
end

function M:_on_btn_exchange()
  if not self._config_ready then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_NotReady")
    return
  end
  if self._remaining_exchange_count <= 0 then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_CycleLimit")
    return
  end
  if self:get_selected_flower_count() ~= self._required_flower_count then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_NotEnough", self._required_flower_count)
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("HairDyeing_FlowerExchange_ConfirmContent", self._reward_item_count), UIUtil.get_text_by_id("HairDyeing_FlowerExchange_Confirm"), UIUtil.get_text_by_id("HairDyeing_FlowerExchange_Cancel"), UIUtil.get_text_by_id("HairDyeing_FlowerExchange_ConfirmTitle"))
  popup:set_callbacks(pack(self, M._request_exchange_confirmed))
  popup:show()
end

function M:_build_material_lists()
  local flower_items = {}
  for item_id, count in pairs(self._selected_counts) do
    if 0 < count then
      table.insert(flower_items, {item_id = item_id, count = count})
    end
  end
  table.sort(flower_items, function(left, right)
    return left.item_id < right.item_id
  end)
  local material_ids = {}
  local material_counts = {}
  for _, item in ipairs(flower_items) do
    table.insert(material_ids, item.item_id)
    table.insert(material_counts, item.count)
  end
  return material_ids, material_counts
end

function M:_request_exchange_confirmed()
  if not self:_can_exchange() then
    return
  end
  self._is_requesting = true
  self:_refresh_exchange_state()
  local material_ids, material_counts = self:_build_material_lists()
  local ok, accepted = xpcall(function()
    return hair_dyeing_module:request_flower_exchange(self._exchange_id, material_ids, material_counts)
  end, debug.traceback)
  if not ok or not accepted then
    Logger.LogError("[HairDyeingFlowerExchange] request failed to send: " .. tostring(accepted))
    self._is_requesting = false
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_Failed")
    self:_refresh_exchange_state()
  end
end

function M:_on_exchange_info_changed(exchange_id)
  if exchange_id ~= 0 and exchange_id ~= self._exchange_id then
    return
  end
  self:_refresh_exchange_config()
  self:_refresh_remaining_count()
  self:_refresh_exchange_state()
end

function M:_on_exchange_result(rsp)
  if not self._is_requesting then
    return
  end
  self._is_requesting = false
  if is_null(rsp) then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_Failed")
    self:_refresh_exchange_state()
    return
  end
  if rsp.Retcode ~= 0 then
    self:_refresh_exchange_state()
    return
  end
  self:_refresh_exchange_config()
  self:_refresh_remaining_count()
  self:_refresh_selection_after_inventory_change()
  local reward_item = rsp.RewardItem
  local reward_items
  if not_null(reward_item) and 0 < reward_item.ItemId and 0 < reward_item.Count then
    reward_items = {
      {
        id = reward_item.ItemId,
        num = reward_item.Count
      }
    }
  else
    reward_items = {
      {
        id = self._reward_item_id,
        num = self._reward_item_count
      }
    }
  end
  common_ui_module:show_reward_dialog_with_text_id("HairDyeing_FlowerExchange_RewardTitle", nil, nil, reward_items)
  if self._on_exchange_success then
    self._on_exchange_success(rsp)
  end
end

return M
