gacha_module = gacha_module or {}

function gacha_module:_init_data()
  self._cur_gacha_id = 0
  self._cur_exchange_index = 0
  self._cur_cloth_pool_index = 0
  self._last_draw_rsp_lua = nil
  self._is_query_by_entrance = false
  self._skip_anim_map = nil
  self._video_played_map = nil
  self._detail_data = nil
  self._history_data = nil
  self._accum_reward_red_map = nil
  self._is_in_draw_show = false
  self._is_request_draw = false
  self:_cancel_draw_show_timeout()
  self:clear_cfg_cache()
end

function gacha_module:set_cur_gacha_id(gacha_id)
  self._cur_gacha_id = gacha_id
end

function gacha_module:get_cur_gacha_id()
  return self._cur_gacha_id or 0
end

function gacha_module:set_cur_exchange_index(index)
  self._cur_exchange_index = index
end

function gacha_module:get_cur_exchange_index()
  return self._cur_exchange_index or 0
end

function gacha_module:set_cur_cloth_pool_index(index)
  self._cur_cloth_pool_index = index
end

function gacha_module:get_cur_cloth_pool_index()
  return self._cur_cloth_pool_index or 0
end

function gacha_module:set_last_draw_rsp_lua(rsp)
  self._last_draw_rsp_lua = rsp
end

function gacha_module:get_last_draw_rsp_lua()
  return self._last_draw_rsp_lua
end

function gacha_module:set_is_query_by_entrance(is_query_by_entrance)
  self._is_query_by_entrance = is_query_by_entrance
end

function gacha_module:get_is_query_by_entrance()
  return self._is_query_by_entrance or false
end

function gacha_module:set_detail_data(data)
  self._detail_data = data
end

function gacha_module:get_detail_data()
  return self._detail_data
end

function gacha_module:set_history_data(data)
  self._history_data = data
end

function gacha_module:get_history_data()
  return self._history_data
end

function gacha_module:set_is_in_draw_show(is_in_draw_show)
  self._is_in_draw_show = is_in_draw_show
  if is_in_draw_show then
    self:_cancel_draw_show_timeout()
    self._draw_show_timer = CsCoroutineManagerUtil.Invoke(GachaConst.draw_show_timeout, function()
      self._draw_show_timer = nil
      self:set_is_in_draw_show(false)
      self:set_is_request_draw(false)
      Logger.LogWarning("[GachaData] draw show timeout")
    end)
  else
    self:_cancel_draw_show_timeout()
  end
end

function gacha_module:_cancel_draw_show_timeout()
  if self._draw_show_timer ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._draw_show_timer)
    self._draw_show_timer = nil
  end
end

function gacha_module:is_in_draw_show()
  return self._is_in_draw_show
end

function gacha_module:set_is_request_draw(is_request_draw)
  self._is_request_draw = is_request_draw
end

function gacha_module:is_request_draw()
  return self._is_request_draw
end

function gacha_module:set_skip_anim(gacha_id, skip)
  self._skip_anim_map = self._skip_anim_map or {}
  self._skip_anim_map[gacha_id] = skip == true
end

function gacha_module:is_skip_anim(gacha_id)
  return self._skip_anim_map ~= nil and self._skip_anim_map[gacha_id] == true
end

function gacha_module:load_skip_anim_data()
  local raw = CsLocalSaveDataUtil.GetString(LocalSaveID.GachaSkipAnim, "")
  local t = {}
  for kv in string.gmatch(raw, "[^&]+") do
    local k, v = string.match(kv, "^([^=]+)=(.*)$")
    local k_num = tonumber(k)
    local v_num = tonumber(v)
    if k_num and v_num then
      t[k_num] = v_num == 1
    end
  end
  self._skip_anim_map = t
end

function gacha_module:save_skip_anim_data()
  if self._skip_anim_map == nil then
    return
  end
  local parts = {}
  for k, v in pairs(self._skip_anim_map) do
    parts[#parts + 1] = tostring(k) .. "=" .. tostring(v and 1 or 0)
  end
  CsLocalSaveDataUtil.SetString(LocalSaveID.GachaSkipAnim, table.concat(parts, "&"))
end

function gacha_module:is_show_skip_toggle(cfg)
  return cfg.tab ~= GachaConst.tab.t1_no_replace
end

function gacha_module:is_video_played(video_id)
  return self._video_played_map ~= nil and self._video_played_map[video_id] == true
end

function gacha_module:mark_video_played(video_id)
  self._video_played_map = self._video_played_map or {}
  self._video_played_map[video_id] = true
end

function gacha_module:load_video_played_data()
  local raw = CsLocalSaveDataUtil.GetString(LocalSaveID.GachaVideoPlayed, "")
  local t = {}
  for kv in string.gmatch(raw, "[^&]+") do
    local k, v = string.match(kv, "^([^=]+)=(.*)$")
    if k then
      t[tonumber(k)] = tonumber(v) == 1
    end
  end
  self._video_played_map = t
end

function gacha_module:save_video_played_data()
  if self._video_played_map == nil then
    return
  end
  local parts = {}
  for k, v in pairs(self._video_played_map) do
    parts[#parts + 1] = tostring(k) .. "=" .. tostring(v and 1 or 0)
  end
  CsLocalSaveDataUtil.SetString(LocalSaveID.GachaVideoPlayed, table.concat(parts, "&"))
end

function gacha_module:get_pool_info(gacha_id)
  return CsGachaModuleUtil.GetPoolInfo(gacha_id)
end

function gacha_module:get_pool_info_map()
  local pool_info_map = dic_to_table(CsGachaModuleUtil.GetPoolInfoMap())
  return pool_info_map
end

function gacha_module:get_last_draw_rsp()
  return CsGachaModuleUtil.GetLastDrawRsp()
end

function gacha_module:get_server_gacha_id_list()
  local gacha_id_list = list_to_table(CsGachaModuleUtil.GetGachaIdList())
  return gacha_id_list
end

function gacha_module:get_total_draw_count(gacha_id)
  return CsGachaModuleUtil.GetTotalDrawCount(gacha_id)
end

function gacha_module:get_claimed_accum_reward_set(gacha_id)
  local set = {}
  local list = list_to_table(CsGachaModuleUtil.GetClaimedAccumRewardIndexList(gacha_id)) or {}
  for i = 1, #list do
    set[list[i]] = true
  end
  return set
end

function gacha_module:get_accum_reward_red_cache(gacha_pool_id)
  if self._accum_reward_red_map == nil then
    return nil
  end
  return self._accum_reward_red_map[gacha_pool_id]
end

function gacha_module:set_accum_reward_red_cache(gacha_pool_id, has_reward)
  self._accum_reward_red_map = self._accum_reward_red_map or {}
  self._accum_reward_red_map[gacha_pool_id] = has_reward == true
end

function gacha_module:clear_accum_reward_red_cache(gacha_pool_id)
  if self._accum_reward_red_map == nil then
    return
  end
  if gacha_pool_id == nil then
    self._accum_reward_red_map = nil
  else
    self._accum_reward_red_map[gacha_pool_id] = nil
  end
end

return gacha_module
