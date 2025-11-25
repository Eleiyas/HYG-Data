npc_module = npc_module or {}

function npc_module:get_npc_entity_by_id(npc_id)
  if 0 < npc_id then
    if self._npc_entity_id == npc_id and not is_null(self._npc_entity_id) then
      return self._npc_entity
    end
    self._npc_entity_id = npc_id
    local guid = CsDataItemManagerUtil.GetNPCGuid(npc_id)
    self._npc_entity = CsEntityManagerUtil.GetEntityByGuid(guid)
    return self._npc_entity
  end
end

function npc_module:get_npc_entity_by_guid(npc_guid)
  if 0 < npc_guid then
    return CsEntityManagerUtil.GetEntityByGuid(npc_guid)
  end
  return nil
end

function npc_module:set_cur_give_item_id(item_id)
  self._cur_give_item_id = item_id or 0
end

function npc_module:set_cur_give_item_config_id(config_id)
  self._cur_give_item_config_id = config_id or 0
end

function npc_module:get_cur_give_item_config_id()
  return self._cur_give_item_config_id or 0
end

return npc_module or {}
