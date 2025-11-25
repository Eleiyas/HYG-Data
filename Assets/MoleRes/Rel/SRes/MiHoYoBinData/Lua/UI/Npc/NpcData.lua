npc_module = npc_module or {}

function npc_module:init_data()
  self._cur_npc_guid = nil
  self._cur_npc_id = nil
  self._cur_give_item_id = 0
  self._npc_entity_id = -1
  self._npc_entity = nil
  self._cur_npc_cloth_guids = nil
  self._following_npc_id = 0
  self._is_npc_following = false
end

function npc_module:set_cur_npc_cfg_id(npc_id)
  npc_id = npc_id or 0
  self._cur_npc_id = npc_id
  if 0 < npc_id then
    self._cur_npc_cloth_guids = EntityUtil.get_all_equip_clothe_guids_by_guid(EntityUtil.get_npc_guid_by_config_id(npc_id))
  else
    self._cur_npc_cloth_guids = nil
  end
  CsWarehouseModuleUtil.SetCurSelectedNpcId(npc_id or 0)
end

function npc_module:get_cur_npc_cfg_id()
  return self._cur_npc_id or 0
end

function npc_module:get_cur_npc_cloth_guids()
  return self._cur_npc_cloth_guids or {}
end

function npc_module:get_cur_npc_id()
  local guid = npc_module:get_cur_npc_guid()
  if guid <= 0 then
    return 0
  end
  local cfg_id = EntityUtil.get_cfg_id_by_guid(guid)
  return cfg_id or 0
end

function npc_module:set_cur_npc_guid(npc_guid)
  if npc_guid and 0 < npc_guid then
    self._cur_npc_guid = npc_guid
  end
end

function npc_module:get_cur_npc_guid()
  return CsPerformanceManagerUtil.Initiator or 0
end

function npc_module:get_knock_bubble_data()
  return self._knock_bubble_guids
end

function npc_module:clear_knock_bubble_data()
  table.clear(self._knock_bubble_guids)
end

function npc_module:get_all_equip_clothes_by_npc_id(npc_id)
  local guids = EntityUtil.get_all_equip_clothe_guids_by_guid(EntityUtil.get_npc_guid_by_config_id(npc_id))
  local ret_tbl = {}
  for _, make_id in ipairs(guids) do
    local item_data = CsWarehouseModuleUtil.GetNPCWarehouseItemByGUID(npc_id, make_id)
    if not is_null(item_data) and item_data.cfg.isshowinpage == 0 then
      table.insert(ret_tbl, item_data)
    end
  end
  return ret_tbl
end

function npc_module:clothe_is_equip_by_npc_id(npc_id, item_data)
  if is_null(item_data) then
    return false
  end
  return CsWarehouseModuleUtil.ItemIsEquippedByNpcId(npc_id, item_data.GUID)
end

return npc_module or {}
