local M = G.Class("GeLianMarketReturnRankPanel", G.UIPanel)
local base = G.UIPanel
local rank_item_cls = "UI/GeLianMarket/Panel/GeLianMarketReturnRankEntryPanel"

function M:init()
  base.init(self)
  self._rows = {}
  self._list_rows = {}
  self._items = {}
  self._self_item = nil
  self._is_scroller_inited = false
  self._is_updating_hidden_toggle = false
end

function M:on_create()
  base.on_create(self)
  self._self_item = self:add_panel(rank_item_cls, self._trans_self_item)
  self:bind_callback(self._tog_switch_show, pack(self, M._on_tog_switch_show))
  self:bind_callback(self._btn_sort, pack(self, M._on_btn_sort))
end

function M:on_enable()
  base.on_enable(self)
  self._tog_switch_show:SetIsOnWithoutNotify(not CsGeLianMarketModuleUtil.IsProfitHidden)
end

function M:on_disable()
  base.on_disable(self)
end

function M:hide_all_action_btns()
  if self._self_item ~= nil then
    self._self_item:hide_action_btns()
  end
  for _, item in pairs(self._items) do
    item:hide_action_btns()
  end
end

function M:on_destroy()
  if self._is_scroller_inited then
    self._grid_scroller:Close()
  end
  self._rows = {}
  self._list_rows = {}
  self._items = {}
  self._self_item = nil
  self._is_scroller_inited = false
  base.on_destroy(self)
end

function M:render(view_data)
  local rank_data = view_data and view_data.return_rank or nil
  self._rows = rank_data and rank_data.rows or {}
  self._list_rows = {}
  local self_row
  for i = 1, #self._rows do
    local row = self._rows[i]
    if row.is_self then
      self_row = row
    end
    self._list_rows[#self._list_rows + 1] = row
  end
  local has_rank_data = #self._list_rows > 0
  self._state_group_return:SetState(has_rank_data and 0 or 1)
  self._self_item:render(self_row, false)
  self._is_updating_hidden_toggle = true
  self._tog_switch_show:SetIsOnWithoutNotify(not rank_data or not rank_data.self_hidden)
  self._is_updating_hidden_toggle = false
  if self._is_scroller_inited then
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), #self._list_rows)
  else
    self._grid_scroller:Init(pack(self, M._refresh_item), #self._list_rows)
    self._is_scroller_inited = true
  end
end

function M:_refresh_item(trans, index)
  local instance_id = trans:GetInstanceID()
  local item = self._items[instance_id]
  if item == nil then
    item = self:add_panel(rank_item_cls, trans)
    self._items[instance_id] = item
  end
  item:render(self._list_rows[index + 1], true)
end

function M:_on_tog_switch_show(is_show)
  if self._is_updating_hidden_toggle then
    return
  end
  self._is_updating_hidden_toggle = true
  CsGeLianMarketModuleUtil.SetProfitHidden(not is_show, function(succeed)
    local is_hidden = CsGeLianMarketModuleUtil.IsProfitHidden == true
    self._is_updating_hidden_toggle = false
    if not self.is_active then
      return
    end
    self._tog_switch_show:SetIsOnWithoutNotify(not is_hidden)
    if not succeed then
      return
    end
    self:_show_profit_hidden_flag_changed_tip(is_hidden)
    for i = 1, #self._rows do
      if self._rows[i].is_self then
        self._rows[i].is_profit_hidden = is_hidden
        self._self_item:render(self._rows[i], false)
        if self._is_scroller_inited then
          self._grid_scroller:ReLoad(pack(self, M._refresh_item), #self._list_rows)
        end
        break
      end
    end
  end)
end

function M:_on_btn_sort()
  local options = {
    {
      title = UIUtil.get_text_by_id("Market_ReturnRank_Sort_Descending"),
      value = "descending"
    },
    {
      title = UIUtil.get_text_by_id("Market_ReturnRank_Sort_Ascending"),
      value = "ascending"
    }
  }
  common_ui_module:show_sort_dialog(options, 1, pack(self, M._on_sort_selected), self._btn_sort.transform, nil, 1)
end

function M:_on_sort_selected(sort_value)
  table.sort(self._list_rows, function(a, b)
    if sort_value == "ascending" then
      return a.rank > b.rank
    end
    return a.rank < b.rank
  end)
  if self._is_scroller_inited then
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), #self._list_rows)
    self._grid_scroller:MoveTo(0)
  end
end

function M:_show_profit_hidden_flag_changed_tip(is_hidden)
  local key = is_hidden and "Market_ReturnRank_SelfHidden" or "Market_ReturnRank_SelfShown"
  UIUtil.show_tips_by_text_id(key)
end

return M
