local M = G.Class("GachaDescriptionPopUp", G.UIWindow)
local base = G.UIWindow
local description_item_cls = GachaConst.item_path.description

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.page_path.description
  self.config.type = EUIType.Dialog
  self._cur_tab = GachaConst.rule_tab.inventory
  self._inventory_items = {}
  self._history_items = {}
  self._record_list = {}
  self._cur_page_history = 0
  self._total_page_history = 1
  self._inventory_data = {}
  self._history_data = {}
  self._gacha_id = 0
  self._gacha_pool_id = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  self:_bind_toggles()
  if not_null(self._btn_previous_history) then
    self:bind_callback(self._btn_previous_history, pack(self, M._on_btn_prev_history))
  end
  if not_null(self._btn_next_history) then
    self:bind_callback(self._btn_next_history, pack(self, M._on_btn_next_history))
  end
  self:add_evt_listener(EventID.GachaDetailResult, pack(self, M._query_detail_result))
  self:add_evt_listener(EventID.GachaHistoryResult, pack(self, M._query_history_result))
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  self._cur_tab = extra ~= nil and extra.tab or GachaConst.rule_tab.inventory
end

function M:on_enable()
  base.on_enable(self)
  if self._toggles == nil then
    self._toggles = {
      [GachaConst.rule_tab.inventory] = self._tog_inventory,
      [GachaConst.rule_tab.details] = self._tog_details,
      [GachaConst.rule_tab.history] = self._tog_history
    }
  end
  local gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  self._gacha_pool_id = activity_cfg and activity_cfg.gachapoolid or 0
  self._gacha_id = gacha_id
  self._cur_page_history = 0
  self:_update_history_page_size()
  local cur_toggle = self._toggles[self._cur_tab]
  if not_null(cur_toggle) then
    cur_toggle:SetIsOnWithoutNotify(true)
  end
  self:_switch_tab(self._cur_tab)
end

function M:on_disable()
  base.on_disable(self)
  self._inventory_data = {}
  self._history_data = {}
end

function M:on_destroy()
  self._inventory_items = {}
  self._history_items = {}
  base.on_destroy(self)
end

function M:_bind_toggles()
  if not_null(self._tog_inventory) then
    self:bind_callback(self._tog_inventory, function(is_on)
      if is_on then
        self:_switch_tab(GachaConst.rule_tab.inventory)
      end
    end)
  end
  if not_null(self._tog_details) then
    self:bind_callback(self._tog_details, function(is_on)
      if is_on then
        self:_switch_tab(GachaConst.rule_tab.details)
      end
    end)
  end
  if not_null(self._tog_history) then
    self:bind_callback(self._tog_history, function(is_on)
      if is_on then
        self:_switch_tab(GachaConst.rule_tab.history)
      end
    end)
  end
end

function M:_switch_tab(tab)
  self._cur_tab = tab
  local is_inventory = tab == GachaConst.rule_tab.inventory
  local is_details = tab == GachaConst.rule_tab.details
  local is_history = tab == GachaConst.rule_tab.history
  UIUtil.set_active(self._inventory, is_inventory)
  UIUtil.set_active(self._details, is_details)
  UIUtil.set_active(self._history, is_history)
  UIUtil.set_active(self._loading_mask, true)
  if is_inventory then
    self:_refresh_inventory()
  elseif is_details then
    self:_refresh_details()
  elseif is_history then
    self:_refresh_history()
  end
end

function M:_refresh_inventory()
  local detail_data = gacha_module:get_detail_data()
  if detail_data == nil then
    gacha_module:request_detail_url()
    return
  end
  self:_refresh_inventory_page()
end

function M:_refresh_inventory_page()
  local detail_data = gacha_module:get_detail_data()
  if detail_data == nil or is_null(self._inventory_scroller) then
    return
  end
  local cur_detail_data = detail_data[self._gacha_id]
  self._inventory_data = cur_detail_data and cur_detail_data.item_probability_list or {}
  local count = #self._inventory_data
  if self._inventory_inited then
    self._inventory_scroller:ReLoad(pack(self, M._refresh_inventory_item), count)
    self._inventory_scroller:MoveTo(0)
  else
    self._inventory_inited = true
    LayoutRebuilder.ForceRebuildLayoutImmediate(self._inventory_scroller.transform.parent)
    self._inventory_scroller:Init(pack(self, M._refresh_inventory_item), count)
  end
  UIUtil.set_active(self._loading_mask, false)
end

function M:_refresh_inventory_item(trans, index)
  local id = trans:GetInstanceID()
  local item_cls = self._inventory_items[id]
  if item_cls == nil then
    item_cls = self:add_panel(description_item_cls, trans)
    self._inventory_items[id] = item_cls
  end
  local data = self._inventory_data[index + 1]
  item_cls:refresh(data, false)
  item_cls:set_active(true)
end

function M:_refresh_details()
  local detail_data = gacha_module:get_detail_data()
  if detail_data == nil then
    gacha_module:request_detail_url()
    return
  end
  self:_refresh_details_page()
end

function M:_query_detail_result(result)
  if not string.is_valid(result) then
    Logger.LogError("[GachaDescriptionPopUp] detail result is empty")
    return
  end
  local json_parse_data = JSON.Parse(result)
  if json_parse_data == nil then
    Logger.LogError("[GachaDescriptionPopUp] detail json parse failed")
    return
  end
  local code_node = json_parse_data:GetValueOrDefault("code", nil)
  local ret_code = code_node ~= nil and code_node.AsInt or -1
  if ret_code ~= 0 then
    Logger.LogError("[GachaDescriptionPopUp] 请求详情说明失败, code: " .. tostring(ret_code))
    return
  end
  local nodes = json_parse_data:GetValueOrDefault("data", nil)
  if nodes == nil then
    Logger.LogError("[GachaDescriptionPopUp] 请求详情说明失败: data 为空")
    return
  end
  local detail_data = {}
  for i = 0, nodes.Count - 1 do
    local item = nodes[i]
    local id_node = item ~= nil and item:GetValueOrDefault("activity_id") or nil
    local gacha_id = id_node ~= nil and id_node.AsInt or 0
    if 0 < gacha_id then
      detail_data[gacha_id] = self:_parse_detail_item(item, gacha_id)
    end
  end
  gacha_module:set_detail_data(detail_data)
  if self._cur_tab == GachaConst.rule_tab.details then
    self:_refresh_details_page()
  elseif self._cur_tab == GachaConst.rule_tab.inventory then
    self:_refresh_inventory_page()
  end
end

function M:_parse_detail_item(item, gacha_id)
  local parse_item = {
    gacha_id = gacha_id,
    times = "",
    content = "",
    item_probability_list = {}
  }
  local contents = item:GetValueOrDefault("contents")
  if contents == nil or contents.Count <= 0 then
    return parse_item
  end
  local content_node = contents[0]:GetValueOrDefault("content")
  local content_value = content_node ~= nil and content_node.Value or ""
  local newline_pos = string.find(content_value, "\n", 1, true)
  if newline_pos then
    local times_value = string.sub(content_value, 1, newline_pos - 1)
    parse_item.times = string.gsub(times_value, "\r$", "")
    parse_item.content = string.sub(content_value, newline_pos + 1)
  else
    parse_item.times = ""
    parse_item.content = content_value
  end
  self:_append_duplicate_coin_text(parse_item, contents[0])
  local probability_list = contents[0]:GetValueOrDefault("item_probability_list")
  if probability_list ~= nil and probability_list.Count > 0 then
    for j = 0, probability_list.Count - 1 do
      local node = probability_list[j]
      local id_node = node:GetValueOrDefault("item_id")
      local item_name = node:GetValueOrDefault("item_name")
      local prob_node = node:GetValueOrDefault("probability")
      table.insert(parse_item.item_probability_list, {
        item_id = id_node ~= nil and id_node.AsInt or 0,
        item_probability = prob_node ~= nil and prob_node.Value or "0%",
        item_name = item_name ~= nil and item_name.Value or ""
      })
    end
  end
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  local pool_id = activity_cfg and activity_cfg.gachapoolid or 0
  for _, entry in ipairs(parse_item.item_probability_list) do
    local pool_cfg = gacha_module:get_pool_cfg_by_item_id(pool_id, entry.item_id)
    entry.sort_index = pool_cfg and pool_cfg.index or 100
  end
  table.sort(parse_item.item_probability_list, function(a, b)
    if a.sort_index ~= b.sort_index then
      return a.sort_index < b.sort_index
    end
    return a.item_id < b.item_id
  end)
  return parse_item
end

local function _replace_placeholder(text, name, coin_name, num_str)
  local args = {
    name or "",
    coin_name or "",
    num_str or ""
  }
  return (string.gsub(text, "%[#(%d)%]", function(idx)
    local n = tonumber(idx) or 0
    local v = args[n + 1]
    return v ~= nil and v or ""
  end))
end

function M:_append_duplicate_coin_text(parse_item, content_node)
  if content_node == nil then
    return
  end
  local text_node = content_node:GetValueOrDefault("duplicate_coin_text")
  local template = text_node ~= nil and text_node.Value or ""
  if not string.is_valid(template) then
    return
  end
  local list_node = content_node:GetValueOrDefault("duplicate_transform_list")
  if list_node == nil or list_node.Count <= 0 then
    return
  end
  local lines = {}
  for i = 0, list_node.Count - 1 do
    local entry = list_node[i]
    local num_node = entry:GetValueOrDefault("trans_num")
    local to_node = entry:GetValueOrDefault("to_item_name")
    local names_node = entry:GetValueOrDefault("item_names")
    local names = {}
    if names_node ~= nil and names_node.Count > 0 then
      for j = 0, names_node.Count - 1 do
        local name_node = names_node[j]
        table.insert(names, name_node ~= nil and name_node.Value or "")
      end
    end
    local num_str = num_node ~= nil and tostring(num_node.AsInt) or ""
    local coin_name = to_node ~= nil and to_node.Value or ""
    local line = _replace_placeholder(template, table.concat(names, "、"), coin_name, num_str)
    if string.is_valid(line) then
      table.insert(lines, line)
    end
  end
  if #lines == 0 then
    return
  end
  local extra = table.concat(lines, "\n")
  if string.is_valid(parse_item.content) then
    parse_item.content = parse_item.content .. "\n" .. extra
  else
    parse_item.content = extra
  end
end

function M:_refresh_details_page()
  self._detail_scroll.verticalScrollbar.value = 1
  local detail_data = gacha_module:get_detail_data()
  local cur_detail_data = detail_data and detail_data[self._gacha_id]
  local activity_time_str = ""
  local content_str = ""
  if cur_detail_data ~= nil then
    activity_time_str = cur_detail_data.times
    content_str = cur_detail_data.content
  end
  UIUtil.set_text(self._txt_time_num_details, activity_time_str)
  UIUtil.set_text(self._txt_time_des_details, content_str)
  UIUtil.set_active(self._loading_mask, false)
end

function M:_refresh_history(cursor_id, is_more)
  local history_data = gacha_module:get_history_data()
  local cur_history_data = history_data and history_data[self._gacha_pool_id]
  if is_more or cur_history_data == nil then
    gacha_module:request_history_url(self._gacha_pool_id, cursor_id)
    return
  end
  self:_refresh_history_page()
end

function M:_query_history_result(result)
  if result == nil or result.GachaPoolId ~= self._gacha_pool_id then
    return
  end
  local history_data = gacha_module:get_history_data()
  if history_data == nil then
    history_data = {}
  end
  local cur_history_data = history_data[result.GachaPoolId]
  if cur_history_data == nil then
    cur_history_data = {}
  end
  cur_history_data.has_more = result.HasMore
  if cur_history_data.next_cursor_id ~= nil and cur_history_data.next_cursor_id == result.NextCursorId then
    self:_update_history_page()
    return
  end
  cur_history_data.next_cursor_id = result.NextCursorId
  if cur_history_data.history_list == nil then
    cur_history_data.history_list = {}
  end
  local json_parse_data = JSON.Parse(result.HistoryJson)
  if json_parse_data == nil then
    Logger.LogError("[GachaDescriptionPopUp]请求历史记录失败: 数据为空")
    return
  end
  local data = json_parse_data:GetValueOrDefault("data", nil)
  if data == nil then
    Logger.LogError("[GachaDescriptionPopUp]请求历史记录失败: 数据为空")
    return
  end
  local records = data:GetValueOrDefault("records", nil)
  if records ~= nil and records.Count > 0 then
    for i = 0, records.Count - 1 do
      local record = records[i]
      local item_id_node = record:GetValueOrDefault("item_id")
      local draw_time_node = record:GetValueOrDefault("draw_time")
      local slot_index_node = record:GetValueOrDefault("slot_index")
      table.insert(cur_history_data.history_list, {
        item_id = item_id_node ~= nil and item_id_node.AsInt or 0,
        draw_time = UIUtil.utc_iso_to_server_time_str(draw_time_node ~= nil and draw_time_node.Value or ""),
        slot_index = slot_index_node ~= nil and slot_index_node.AsInt or 0
      })
    end
  end
  history_data[result.GachaPoolId] = cur_history_data
  gacha_module:set_history_data(history_data)
  self:_update_history_page_size()
  self:_update_history_page()
end

function M:_update_history_page_size()
  local history_data = gacha_module:get_history_data()
  local cur_history_data = history_data and history_data[self._gacha_pool_id]
  if cur_history_data == nil then
    self._total_page_history = 1
    return
  end
  self._total_page_history = math.max(1, math.ceil(#cur_history_data.history_list / GachaConst.history_page_size))
end

function M:_update_history_page()
  if self._cur_tab == GachaConst.rule_tab.history then
    if self._cur_page_history < self._total_page_history then
      self._cur_page_history = self._cur_page_history + 1
    end
    self:_refresh_history_page()
  end
end

function M:_refresh_history_page()
  UIUtil.set_text_by_id(self._txt_history_des, "Gacha_History_Top_Tip")
  local history_data = gacha_module:get_history_data()
  self._history_data = history_data and history_data[self._gacha_pool_id] or {}
  local history_list = self._history_data.history_list or {}
  if self._cur_page_history <= 0 then
    self._cur_page_history = 1
  elseif self._cur_page_history > self._total_page_history then
    self._cur_page_history = self._total_page_history
  end
  self._history_scroll.verticalScrollbar.value = 1
  local page_size = GachaConst.history_page_size
  local start_index = (self._cur_page_history - 1) * page_size
  for i = 1, page_size do
    local history = history_list[start_index + i]
    local item_cls = self._history_items[i]
    if history ~= nil then
      if item_cls == nil and not is_null(self._history_content) then
        local obj = self._history_content:AddItem(0)
        item_cls = self:add_panel(description_item_cls, obj)
        self._history_items[i] = item_cls
      end
      if item_cls ~= nil then
        item_cls:refresh(history, true, self._gacha_pool_id)
        item_cls:set_active(true)
      end
    elseif item_cls ~= nil then
      item_cls:set_active(false)
    end
  end
  if not_null(self._txt_page_num_history) then
    UIUtil.set_text(self._txt_page_num_history, string.format("%d", self._cur_page_history))
  end
  UIUtil.set_active(self._btn_previous_history, self._cur_page_history > 1)
  UIUtil.set_active(self._btn_next_history, self._cur_page_history < self._total_page_history or self._history_data.has_more)
  UIUtil.set_active(self._loading_mask, false)
end

function M:_on_btn_prev_history()
  if self._cur_page_history > 1 then
    self._cur_page_history = self._cur_page_history - 1
    self:_refresh_history_page()
  end
end

function M:_on_btn_next_history()
  if self._cur_page_history < self._total_page_history then
    self._cur_page_history = self._cur_page_history + 1
    self:_refresh_history_page()
  elseif self._history_data.has_more then
    self:_refresh_history(self._history_data.next_cursor_id, true)
  end
end

return M
