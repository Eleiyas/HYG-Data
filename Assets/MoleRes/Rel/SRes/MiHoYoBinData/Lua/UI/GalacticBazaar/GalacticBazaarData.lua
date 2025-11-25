galactic_bazaar_module = galactic_bazaar_module or {}

function galactic_bazaar_module:custom_string_split(str, delimiter, trim_whitespace)
  if not str or str == "" then
    return {}
  end
  delimiter = delimiter or ","
  trim_whitespace = trim_whitespace == nil and true or trim_whitespace
  local result = {}
  local pattern = "([^" .. delimiter .. "]+)"
  for match in string.gmatch(str, pattern) do
    if trim_whitespace then
      match = string.gsub(match, "^%s*(.-)%s*$", "%1")
    end
    if match ~= "" then
      table.insert(result, match)
    end
  end
  return result
end

function galactic_bazaar_module:dance_activity_matching_player_list()
  local player_list = CsSceneActivityModuleUtil.GetActivityMatchPlayerInfoList(galactic_bazaar_module.activity_id)
  if player_list then
    self.matching_person_list = list_to_table(player_list)
    self.matching_count = table.count(self.matching_person_list)
  end
end

function galactic_bazaar_module:dance_activity_dancing_player_list()
  local player_list = CsSceneActivityModuleUtil.GetDancePlayerInfoList(galactic_bazaar_module.activity_id)
  if player_list then
    self.dancing_person_list = list_to_table(player_list)
  end
end

function galactic_bazaar_module:get_dancing_action_list()
  local ids_str = dic_to_table(CsUIUtil.GetTable(typeof(CS.BPlayerCfg)))[76].value
  ids_str = "1,2,3"
  local action_icons = {
    [1] = "UISprite/Load/StarMarket/Icon_Dancing_HandLeft",
    [2] = "UISprite/Load/StarMarket/Icon_Dancing_HandUp",
    [3] = "UISprite/Load/StarMarket/Icon_Dancing_HandRight"
  }
  local ids = self:custom_string_split(ids_str, ",", true)
  local action_list = {}
  for _, id in ipairs(ids) do
    local action_cfg = {
      id = tonumber(id),
      iconpath = action_icons[tonumber(id)],
      uistate = id - 1
    }
    if action_cfg then
      table.insert(action_list, action_cfg)
    end
  end
  return action_list
end

function galactic_bazaar_module:get_reaction_list()
  local ids_str = dic_to_table(CsUIUtil.GetTable(typeof(CS.BPlayerCfg)))[106].paramstr
  local ids = self:custom_string_split(ids_str, ",", true)
  local reaction_list = {}
  for _, id in ipairs(ids) do
    if GameplayUtility.CheckReactionUnlock(tonumber(id)) then
      local action_cfg = LocalDataUtil.get_value(typeof(CS.BReactionCfg), tonumber(id))
      if action_cfg then
        table.insert(reaction_list, action_cfg)
      end
    end
  end
  return reaction_list
end

function galactic_bazaar_module:Get_dance_finish_score_rank()
  local score_list = CsSceneActivityModuleUtil.GetDancePlayerInfoList(galactic_bazaar_module.activity_id)
  if score_list then
    self.dance_finish_score_list = list_to_table(score_list)
  end
  local res = {}
  if not self.dance_finish_score_list or #self.dance_finish_score_list == 0 then
    return {
      [player_module:get_player_uid()] = {score = 0, rank = 0}
    }
  end
  table.sort(self.dance_finish_score_list, function(a, b)
    return a.Score > b.Score
  end)
  local cur_rank = 1
  for i, score_data in ipairs(self.dance_finish_score_list) do
    if self.dance_finish_score_list[i - 1] and self.dance_finish_score_list[i - 1].Score > score_data.Score then
      cur_rank = cur_rank + 1
    end
    res[score_data.PlayerUid] = {
      score = score_data.Score,
      rank = cur_rank
    }
  end
  return res
end

function galactic_bazaar_module:get_dance_score_level_list()
  local info = self:get_dance_settlement_info(self.cur_show_player)
  local res = {}
  table.insert(res, {
    name = UIUtil.get_text_by_id("RhythmShow_Evaluate_1"),
    point = info.PerfectCnt
  })
  table.insert(res, {
    name = UIUtil.get_text_by_id("RhythmShow_Evaluate_2"),
    point = info.GoodCnt
  })
  table.insert(res, {
    name = UIUtil.get_text_by_id("RhythmShow_Evaluate_3"),
    point = info.MissCnt
  })
  return res
end

function galactic_bazaar_module:get_dance_appraise(player_uid)
  local info = CsSceneActivityModuleUtil.GetDancePlayerAcoreRankInfo(player_uid)
  if info then
    return info.appraise
  end
  return "D"
end

function galactic_bazaar_module:get_dance_settlement_info(player_uid)
  local settlement_info = CsSceneActivityModuleUtil.GetDancePlayerSettlementInfo(player_uid)
  if settlement_info then
    self.dance_settlement_info = settlement_info
  end
  return self.dance_settlement_info
end

function galactic_bazaar_module:get_dance_settlement_info_slider()
  self.settlement_info_list = list_to_table(CsSceneActivityModuleUtil.GetDancePlayerSettlementInfo())
  if #self.settlement_info_list < 1 then
    return nil
  end
  local total_score = 0
  for _, settlement_info in ipairs(self.settlement_info_list) do
    total_score = total_score + settlement_info.CurScore
  end
  total_score = total_score + self.settlement_info_list[1].TeamScore
  return total_score
end

function galactic_bazaar_module:get_bulletin_list()
  local bulletin_list = LocalDataUtil.get_table(typeof(CS.BMarketBulletinCfg))
  if bulletin_list then
    self.bulletin_list = list_to_table(bulletin_list)
  end
  return self.bulletin_list
end

function galactic_bazaar_module:get_dance_shop_list()
  self.dance_shop_list = {}
  local shop_list = list_to_table(CsSceneActivityModuleUtil.GetBazzarShopGoodsList())
  for _, goods_id in ipairs(shop_list) do
    local goods_cfg = LocalDataUtil.get_value(typeof(CS.BStoreCfg), goods_id)
    if goods_cfg then
      table.insert(self.dance_shop_list, goods_cfg)
    end
  end
  return self.dance_shop_list
end

function galactic_bazaar_module:check_good_sold_out(good_id)
  local cfg = LocalDataUtil.get_value(typeof(CS.BStoreCfg), good_id)
  if cfg.limittype ~= 0 then
    local buy_count = CsSceneActivityModuleUtil.GetBazzarBuyGoodsCount(cfg.id)
    if buy_count >= cfg.availcount then
      return true
    else
      return false
    end
  else
    return false
  end
end

function galactic_bazaar_module:get_market_task_cfg(task_id)
  local cfg = LocalDataUtil.get_value(typeof(CS.BMarketTaskCfg), task_id)
  return cfg
end

function galactic_bazaar_module:get_random_pool_cfg(id)
  local cfg = LocalDataUtil.get_value(typeof(CS.BRandomPoolCfg), id)
  return list_to_table(cfg)
end

return galactic_bazaar_module
