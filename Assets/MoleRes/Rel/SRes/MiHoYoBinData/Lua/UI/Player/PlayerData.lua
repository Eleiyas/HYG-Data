player_module = player_module or {}

function player_module:get_player_data()
  if is_null(self._player_data) then
    self._player_data = CsPlayerModuleUtil.playerData
  end
  return self._player_data
end

function player_module:get_player_entity()
  if is_null(CsEntityManagerUtil) or CsEntityManagerUtil.IsNull() or is_null(CsEntityManagerUtil.avatarManager) then
    return nil
  end
  self._player_entity = CsEntityManagerUtil.avatarManager:GetPlayer()
  return self._player_entity
end

function player_module:get_player_position()
  if player_module:get_player_entity() then
    return player_module:get_player_entity().root.transform:GetPosition()
  end
  return 0, 0, 0
end

function player_module:get_player_input()
  if is_null(self._player_input) then
    self._player_input = InputManagerIns:get_player_input_component()
  end
  return self._player_input
end

function player_module:can_switch_tool()
  local is_can_switch = false
  local player_entity = player_module:get_player_entity()
  if not is_null(player_entity) then
    is_can_switch = player_entity:CanSwitchTool() and player_module:get_can_equip_tool()
  end
  return is_can_switch
end

function player_module:get_can_equip_tool()
  return CsGameplayUtilitiesPermissionUtil.GetPermissionOfOperation(PlayerOpType.EquipItem)
end

function player_module:get_player_interaction_mask_state()
  return self._interaction_mask_is_open or false
end

function player_module:get_player_uid()
  return player_module:get_player_data().uid
end

function player_module:get_player_guid()
  return player_module:get_player_data().PlayerGuid
end

function player_module:get_player_name()
  return player_module:get_player_data().playerServerData.NameID
end

function player_module:set_is_right_away_hide_tool_list(is_right_away_hide_tool_list)
  self._is_right_away_hide_tool_list = is_right_away_hide_tool_list or false
end

function player_module:get_is_right_away_hide_tool_list()
  return self._is_right_away_hide_tool_list or false
end

function player_module:get_all_tool()
  if self._tbl_all_tools == nil then
    local player_data = player_module:get_player_data()
    if not is_null(player_data) then
      self._tbl_all_tools = list_to_table(player_data:GetCurHandInTypeQuickItemList())
    end
  end
  local ret_tbl = {}
  for i, v in ipairs(self._tbl_all_tools or {}) do
    ret_tbl[i] = v
  end
  return ret_tbl
end

function player_module:get_cur_equip_tool_index()
  if self._cur_equip_tool_index <= 0 then
    local player_data = player_module:get_player_data()
    local all_tools = player_module:get_all_tool()
    if not is_null(player_data) then
      self._cur_equip_tool_index = 0
      local cur_tool_guid = player_data:GetCurHandInItemGuid()
      for i, v in pairs(all_tools) do
        if cur_tool_guid ~= 0 and v.ItemGuid == cur_tool_guid or cur_tool_guid == 0 and v.BareSlot then
          self._cur_equip_tool_index = i
          break
        end
      end
    end
  end
  return self._cur_equip_tool_index or 0
end

function player_module:get_cur_equip_item()
  local player_data = player_module:get_player_data()
  if not is_null(player_data) then
    return player_data.equipItem
  end
  return nil
end

function player_module:get_tbl_have_tools()
  if self._tbl_have_tools == nil then
    self._tbl_have_tools = {}
    local all_tools = player_module:get_all_tool()
    for _, v in ipairs(all_tools) do
      if v.ConfigId ~= 0 then
        table.insert(self._tbl_have_tools, v)
      end
    end
  end
  return self._tbl_have_tools
end

function player_module:set_last_equip_make_guid(make_guid)
  if make_guid and 0 < make_guid and self._last_equip_make_guid ~= make_guid then
    self._last_equip_make_guid = make_guid
  end
end

function player_module:get_last_equip_make_guid()
  return self._last_equip_make_guid or 0
end

function player_module:get_next_tool_make_id(is_next)
  if not player_module:can_switch_tool() then
    return
  end
  local have_tools = player_module:get_tbl_have_tools()
  local ret_make_id = 0
  if 1 < #have_tools then
    local cur_make_id = player_module:get_player_data():GetCurHandInItemGuid()
    if 0 < cur_make_id then
      local is_empty_handed = false
      local cur_tool_info
      if is_next then
        for i = #have_tools, 1, -1 do
          if have_tools[i].ItemGuid == cur_make_id then
            if i == 1 then
              cur_tool_info = have_tools[#have_tools]
            else
              cur_tool_info = have_tools[i - 1]
            end
            ret_make_id = cur_tool_info.ItemGuid
            is_empty_handed = 0 > cur_tool_info.ConfigId
            if ret_make_id ~= 0 or is_empty_handed then
              break
            end
            cur_make_id = 0
          end
        end
      else
        for i, v in ipairs(have_tools) do
          if v.ItemGuid == cur_make_id then
            if i == #have_tools then
              cur_tool_info = have_tools[1]
            else
              cur_tool_info = have_tools[i + 1]
            end
            ret_make_id = cur_tool_info.ItemGuid
            is_empty_handed = 0 > cur_tool_info.ConfigId
            if ret_make_id ~= 0 or is_empty_handed then
              break
            end
            cur_make_id = 0
          end
        end
      end
    else
      local index = 1
      if is_next then
        local cur_index = #have_tools
        while 1 < cur_index do
          if 0 < have_tools[cur_index].ItemGuid then
            index = cur_index
            break
          end
          cur_index = cur_index - 1
        end
      else
        local cur_index = 2
        while cur_index <= #have_tools do
          if 0 < have_tools[cur_index].ItemGuid then
            index = cur_index
            break
          end
          cur_index = cur_index + 1
        end
      end
      ret_make_id = have_tools[index].ItemGuid
    end
  end
  return ret_make_id
end

function player_module:set_need_show_strength_ui_state(is_need_show)
  self._is_need_show_strength_ui = is_need_show or false
end

function player_module:get_need_show_strength_ui_state()
  return self._is_need_show_strength_ui or false
end

function player_module:get_player_pos_new()
  local is_get, x, y, z = EntityUtil.try_get_entity_position_by_guid(EntityUtil.get_player_entity_guid())
  if is_get then
    return x, y, z
  end
  return 0, 0, 0
end

return player_module or {}
