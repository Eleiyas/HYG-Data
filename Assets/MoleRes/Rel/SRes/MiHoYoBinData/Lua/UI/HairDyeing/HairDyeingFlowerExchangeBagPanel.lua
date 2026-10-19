local M = G.Class("HairDyeingFlowerExchangeBagPanel", "UI/HairDyeing/HairDyeingFlowerBagPanel")
local base = G.HairDyeingFlowerBagPanel
local title_text_id = "HairDyeing_FlowerExchange_SelectCount"

function M:refresh_ui(tog_sort_type)
  base.refresh_ui(self, tog_sort_type)
  if not is_null(self._ui_state_group_filter) then
    self._ui_state_group_filter:SetState(0)
  end
end

function M:refresh_title()
  if is_null(self._txt_title) then
    return
  end
  local selected_count = self.holder and self.holder:get_selected_flower_count() or 0
  local required_count = self.holder and self.holder:get_required_flower_count() or 0
  UIUtil.set_text_by_id(self._txt_title, title_text_id, selected_count, required_count)
end

function M:set_select_num_keep_focus(guid, num)
  num = math.max(0, math.floor((num or 0) + 0.5))
  local item = self:get_item_by_guid(guid)
  if num <= 0 then
    self._tbl_cur_multi_stack[guid] = nil
    back_bag_module:set_select_stack(guid, nil)
  else
    self._tbl_cur_multi_stack[guid] = num
    if not is_null(item) then
      back_bag_module:change_select_stack(item, num)
    end
  end
  local index_map = self._tbl_item_data_guid_and_index and self._tbl_item_data_guid_and_index[self.cur_tog_type]
  local index = index_map and index_map[guid]
  if index ~= nil then
    local cls = self:_get_item_cls_and_data_by_index(index)
    if not is_null(cls) then
      cls:set_cur_num_txt(num, 0 < num)
      cls:refresh()
    end
  end
end

function M:get_item_guids(select_index)
  local guids = base.get_item_guids(self, select_index)
  table.sort(guids, function(left_guid, right_guid)
    local left = self:get_item_by_guid(left_guid)
    local right = self:get_item_by_guid(right_guid)
    local left_id = not is_null(left) and left.ConfigId or 0
    local right_id = not is_null(right) and right.ConfigId or 0
    return left_id < right_id
  end)
  return guids
end

return M
