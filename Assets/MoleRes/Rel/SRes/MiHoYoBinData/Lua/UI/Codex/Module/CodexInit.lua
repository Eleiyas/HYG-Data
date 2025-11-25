codex_module = codex_module or {}
codex_module._cname = "codex_module"
lua_module_mgr:require("UI/Codex/Module/CodexData")
lua_module_mgr:require("UI/Codex/Module/CodexMain")
lua_module_mgr:require("UI/Codex/Module/CodexCommon")
local type_ctrl_class_path = "UI/Codex/Module/CodexTypeCtrlBase"
local unlocked_types = {
  [CodexDataType.Creature] = 1,
  [CodexDataType.Furniture] = 1
}
codex_module.detail_item_type = {
  title = 1,
  normal_info = 2,
  material_info = 3,
  group_info = 4,
  obtain_info = 5,
  reward_info = 6,
  museum_info = 7,
  chain_info = 8,
  space = 9,
  topic_quest = 10,
  topic_reward = 11
}
codex_module.detail_item_cls = {
  [codex_module.detail_item_type.title] = "UI/Codex/DetailPage/Component/DetailInfoTitleItem",
  [codex_module.detail_item_type.normal_info] = "UI/Codex/DetailPage/Component/DetailInfoItem",
  [codex_module.detail_item_type.material_info] = "UI/Codex/DetailPage/Component/DetailComponentItem",
  [codex_module.detail_item_type.group_info] = "UI/Codex/DetailPage/Component/DetailPackageItem",
  [codex_module.detail_item_type.obtain_info] = "UI/Item/SourceItem",
  [codex_module.detail_item_type.reward_info] = "UI/Codex/DetailPage/Component/DetailRewardItem",
  [codex_module.detail_item_type.museum_info] = "UI/Codex/DetailPage/Component/DetailMuseumInfoItem",
  [codex_module.detail_item_type.chain_info] = "UI/Codex/DetailPage/Component/DetailChainListItem",
  [codex_module.detail_item_type.space] = "UI/Codex/DetailPage/Component/DetailComponentSpace",
  [codex_module.detail_item_type.topic_quest] = "UI/Codex/DetailPage/Component/DetailTopicItem",
  [codex_module.detail_item_type.topic_reward] = "UI/Codex/DetailPage/Component/DetailTopicRewardItem"
}
codex_module.topic_type = {Necessary = 0, Optional = 1}

function codex_module:init()
  self._all_data = nil
  self._type_maps = nil
  self._type_ctrls = nil
  self._sub_type_to_type_cache = nil
  self._type_cfgs = nil
  self._total_score_cfgs = nil
  self._task_rank_cfgs = nil
  self._codex_item_pool = {}
  self._creature_new_size = nil
  self:_init_total_score_cfgs()
  self:_init_task_rank_cfgs()
  self:_init_type_cfgs()
  self:_register_event_listener()
end

function codex_module:_register_event_listener()
  self:_remove_events()
  self._events = {
    [EventID.CodexDataUpdate] = pack(self, codex_module._on_codex_data_update)
  }
  for evt_id, func in pairs(self._events) do
    EventCenter.LuaAddListener(evt_id, func)
  end
end

function codex_module:_remove_events()
  if self._events == nil then
    return
  end
  for evt_id, func in pairs(self._events) do
    EventCenter.LuaRemoveListener(evt_id, func)
  end
  self._events = nil
end

function codex_module:_on_codex_data_update(data)
  local codex_data = self:get_data_by_id(data.Id)
  if is_null(codex_data) or not self:is_codex_unlocked() then
    return
  end
  local show_hud = false
  if data.Type.value__ == 1 then
    red_point_module:delete_record_with_id(codex_module.red_point_type_type_tog, codex_data.Type.value__)
    red_point_module:delete_record_with_id(codex_module.red_point_type_sub_type_tog, codex_data.SubType.value__)
    show_hud = true
  elseif data.Type.value__ == 2 then
    show_hud = true
  elseif data.Type.value__ == 3 then
    local sub_type_ctrl = self:get_sub_type_controller(codex_data.Type, codex_data.SubType)
    if sub_type_ctrl and 2 <= sub_type_ctrl:get_sub_type_level() then
      show_hud = true
    end
  elseif data.Type.value__ == 6 then
    self:record_creature_new_size(data.Id)
  end
  if not show_hud then
    return
  end
  local show_data = {
    id = data.Id,
    data = codex_data,
    type = data.Type
  }
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.codex_update_tip, show_data)
end

function codex_module:is_type_unlocked(type)
  return unlocked_types[type] ~= nil
end

function codex_module:get_all_data()
  if self._all_data == nil then
    self:_init_all_data()
  end
  return self._all_data
end

function codex_module:get_data_by_id(id)
  if self._all_data == nil then
    self:_init_all_data()
  end
  return self._all_data[id]
end

function codex_module:get_data_by_id_list(id_list)
  if self._all_data == nil then
    self:_init_all_data()
  end
  local data_list = {}
  for i = 1, #id_list do
    table.insert(data_list, self._all_data[id_list[i]])
  end
  return data_list
end

function codex_module:get_type_maps()
  if self._type_maps == nil then
    self:_init_type_maps()
  end
  return self._type_maps
end

function codex_module:get_total_score_cfgs()
  if self._total_score_cfgs ~= nil or self:_init_total_score_cfgs() then
    return self._total_score_cfgs
  end
  return nil
end

function codex_module:close()
  self._all_data = nil
  self._type_maps = nil
  self._sub_type_to_type_cache = nil
  self._total_score_cfgs = nil
  self:_clear_type_ctrls()
  self:_remove_events()
end

function codex_module:_init_all_data()
  local cs_all_data_dic = CsCodexModuleUtil.AllCodexData
  self._all_data = dic_to_table(cs_all_data_dic)
  return true
end

function codex_module:_init_type_maps()
  local cs_type_dic = CsCodexModuleUtil.TypeToSubTypeDic
  local type_to_sub_type_lst_tbl = dic_to_table(cs_type_dic)
  self._type_maps = {}
  for type, sub_type_lst in pairs(type_to_sub_type_lst_tbl) do
    self._type_maps[type] = list_to_table(sub_type_lst)
  end
  return true
end

function codex_module:_init_type_ctrls()
  if self._type_maps == nil then
    self:_init_type_maps()
  end
  self._type_ctrls = {}
  for type, _ in pairs(self._type_maps) do
    local type_ctrl = G.New(type_ctrl_class_path)
    type_ctrl:init(type)
    self._type_ctrls[type] = type_ctrl
  end
  return true
end

function codex_module:_init_total_score_cfgs()
  self._total_score_cfgs = dic_to_table(LocalDataUtil.get_table(typeof(CS.BCodexTotalScoreCfg)))
  return true
end

function codex_module:_init_task_rank_cfgs()
  self._task_rank_cfgs = dic_to_table(LocalDataUtil.get_table(typeof(CS.BCodexTaskRankCfg)))
  return true
end

function codex_module:_init_type_cfgs()
  self._type_cfgs = LocalDataUtil.get_table(typeof(CS.BArchiveTypeCfg))
  return true
end

function codex_module:_clear_type_ctrls()
  if self._type_ctrls == nil then
    return true
  end
  for _, ctrl in pairs(self._type_ctrls) do
    ctrl:Delete()
  end
  self._type_ctrls = nil
  return true
end

return codex_module
