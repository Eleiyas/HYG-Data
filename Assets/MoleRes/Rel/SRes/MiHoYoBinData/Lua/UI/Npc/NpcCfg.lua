npc_module = npc_module or {}

function npc_module:_load_npc_cfg()
  self._all_npc_cfg = {}
  self._npc_gift_dialog_selectors = {}
  local temp_all_npc_cfg = dic_to_table(CsUIUtil.GetTable(typeof(CS.BNpcCfg)))
  for i, v in pairs(temp_all_npc_cfg) do
    self._all_npc_cfg[v.id] = v
  end
end

function npc_module:get_npc_cfg(npc_id)
  local ret_cfg
  if npc_id == nil then
    Logger.LogError("获取NPC配置错误，无效的npcId!!!  **pos = npc:_get_npc_cfg **")
    return ret_cfg
  end
  if self._all_npc_cfg == nil then
    self:_load_npc_cfg()
  end
  ret_cfg = self._all_npc_cfg[npc_id]
  if ret_cfg == nil then
    Logger.LogError("无效的NPC配置！！！请检查配置文件！！！ **pos = npc:_get_npc_cfg ** npcId = " .. npc_id)
  end
  return ret_cfg
end

return npc_module or {}
