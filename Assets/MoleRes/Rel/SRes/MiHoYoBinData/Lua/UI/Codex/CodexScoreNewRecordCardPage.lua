local M = G.Class("CodexScoreNewRecordCardPage", G.UIPanel)
local base = G.UIPanel
local TYPE_STATE_FURNITURE_ETC = 3
local CREATURE_SUBTYPE_TO_STATE = {
  [CodexDataSubType.CreatureFish] = 0,
  [CodexDataSubType.CreatureSeaFood] = 1,
  [CodexDataSubType.CreatureInsect] = 2
}
local QUALITY_SCORE_MULTIPLIER = {
  [4] = 4,
  [3] = 4,
  [2] = 2
}
local QUALITY_TEXT_MAP = {
  [4] = "CodexScore_MagicRank",
  [3] = "CodexScore_GoldenRank",
  [2] = "CodexScore_PurpleRank"
}
local RANK_LOWEST = 0
local CARD_ENTER_ANIMATION_NAME = "anim_codexscorenewrecordcardpage_in"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreNewRecordCardPage"
  self._rare_data_list = nil
  self._card_index = 1
  self._card_total = 0
  self._star_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_next) then
    self:bind_callback(self._btn_next, pack(self, M._on_tap))
  end
  if not_null(self._btn_skip) then
    self:bind_callback(self._btn_skip, pack(self, M._on_skip))
  end
end

function M:_on_tap()
  self:_show_next()
end

function M:_on_skip()
  self:_finish()
end

function M:_init_data()
  local data = self:get_extra_data()
  if is_null(data) then
    return
  end
  self._rare_data_list = data.rare_data_list or {}
  self._card_total = #self._rare_data_list
  self._card_index = 1
end

function M:_refresh_view()
  if is_null(self._rare_data_list) or self._card_total == 0 then
    return
  end
  local rare_data = self._rare_data_list[self._card_index]
  if is_null(rare_data) then
    return
  end
  local curr_data = rare_data.curr_data
  if is_null(curr_data) then
    return
  end
  local is_creature = curr_data.Type == CodexDataType.Creature
  local rank = not_null(curr_data.ItemCfg) and (curr_data.ItemCfg.rank or 0) or 0
  self:_refresh_name(curr_data)
  self:_refresh_icon(curr_data)
  self:_refresh_type_state(curr_data, is_creature)
  self:_refresh_quality(curr_data, rank)
  self:_refresh_star_section(curr_data, is_creature)
  self:_refresh_total(rare_data, curr_data, rank)
end

function M:_show_next()
  if self._card_index < self._card_total then
    self._card_index = self._card_index + 1
    self:_refresh_view()
    self:play_anim(CARD_ENTER_ANIMATION_NAME)
  else
    self:_finish()
  end
end

function M:_finish()
  self.holder:on_card_complete()
end

function M:_refresh_name(curr_data)
  if is_null(self._txt_name) then
    return
  end
  local item_name = not_null(curr_data.IdCfg) and curr_data.IdCfg.name or ""
  UIUtil.set_text(self._txt_name, item_name)
end

function M:_refresh_icon(curr_data)
  if is_null(self._img_icon_dynamic) or is_null(curr_data.IdCfg) then
    return
  end
  local icon_id = curr_data.IdCfg.id or 0
  item_module:set_item_big_icon_with_prismatic(self._img_icon_dynamic, 0, item_module:get_cfg_by_id(icon_id), self:get_load_proxy(), self._img_icon_dynamic_prismatic)
end

function M:_refresh_type_state(curr_data, is_creature)
  if is_null(self._ui_state_group_type) then
    return
  end
  local state = TYPE_STATE_FURNITURE_ETC
  if is_creature then
    state = CREATURE_SUBTYPE_TO_STATE[curr_data.SubType] or TYPE_STATE_FURNITURE_ETC
  end
  self._ui_state_group_type:SetState(state)
end

function M:_refresh_quality(curr_data, rank)
  if not_null(self._ui_state_group_quality) then
    self._ui_state_group_quality:SetState(rank)
  end
  local is_creature = curr_data.Type == CodexDataType.Creature
  local multiplier
  if is_creature then
    multiplier = self:_calc_creature_quality_multiplier(curr_data, rank)
  else
    multiplier = QUALITY_SCORE_MULTIPLIER[rank]
  end
  if not_null(self._trans_quality) then
    UIUtil.set_active(self._trans_quality, multiplier ~= nil)
  end
  if multiplier == nil then
    return
  end
  if not_null(self._txt_num_quality) then
    UIUtil.set_text(self._txt_num_quality, "x" .. multiplier)
  end
  if not_null(self._txt_quality_content) and QUALITY_TEXT_MAP[rank] then
    UIUtil.set_text_by_id(self._txt_quality_content, QUALITY_TEXT_MAP[rank])
  end
end

function M:_calc_creature_quality_multiplier(curr_data, rank)
  if QUALITY_SCORE_MULTIPLIER[rank] == nil then
    return nil
  end
  local creature = curr_data.ServerData and curr_data.ServerData.Creature or nil
  local max_stars = creature ~= nil and creature.MaxStars or 0
  if max_stars <= 0 then
    return nil
  end
  local sub_type_ctrl = codex_module:get_sub_type_controller(curr_data.Type, curr_data.SubType)
  local sub_type_cfg = sub_type_ctrl and sub_type_ctrl:get_sub_type_cfg() or nil
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if tag == nil then
    return nil
  end
  local curr_score = codex_module:get_creature_star_score(tag, rank, max_stars)
  local base_score = codex_module:get_creature_star_score(tag, RANK_LOWEST, max_stars)
  if base_score <= 0 then
    return nil
  end
  return math.floor(curr_score / base_score)
end

function M:_refresh_star_section(curr_data, is_creature)
  if not_null(self._trans_size) then
    UIUtil.set_active(self._trans_size, is_creature)
  end
  if not_null(self._trans_star_list) then
    UIUtil.set_active(self._trans_star_list, is_creature)
  end
  if not is_creature then
    self:_refresh_stars(0)
    return
  end
  local creature = curr_data.ServerData and curr_data.ServerData.Creature or nil
  local max_stars = creature ~= nil and creature.MaxStars or 0
  self:_refresh_stars(max_stars)
  if not_null(self._txt_size_content) then
    local unit_text = UIUtil.get_text_by_id("Codex_SizeCM")
    UIUtil.set_text(self._txt_size_content, string.format("%s%s", TextMapFormatUtil.FormatDecimal(curr_data.Size or 0, 2), unit_text))
  end
  if not_null(self._txt_size_num) then
    local star_score = self:_get_creature_single_star_score(curr_data, max_stars, RANK_LOWEST)
    UIUtil.set_text(self._txt_size_num, "+" .. TextMapFormatUtil.FormatInteger(star_score))
  end
end

function M:_get_creature_star_score(curr_data, max_stars, rank)
  local sub_type_ctrl = codex_module:get_sub_type_controller(curr_data.Type, curr_data.SubType)
  local sub_type_cfg = sub_type_ctrl and sub_type_ctrl:get_sub_type_cfg() or nil
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if rank == nil then
    rank = not_null(curr_data.ItemCfg) and (curr_data.ItemCfg.rank or 0) or 0
  end
  if tag == nil then
    return 0
  end
  return codex_module:get_creature_star_score(tag, rank, max_stars)
end

function M:_get_creature_single_star_score(curr_data, star, rank)
  local sub_type_ctrl = codex_module:get_sub_type_controller(curr_data.Type, curr_data.SubType)
  local sub_type_cfg = sub_type_ctrl and sub_type_ctrl:get_sub_type_cfg() or nil
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if rank == nil then
    rank = not_null(curr_data.ItemCfg) and (curr_data.ItemCfg.rank or 0) or 0
  end
  if tag == nil or star <= 0 then
    return 0
  end
  local cumulative = codex_module:get_creature_star_score(tag, rank, star)
  local prev_cumulative = 0
  if 1 < star then
    prev_cumulative = codex_module:get_creature_star_score(tag, rank, star - 1)
  end
  return cumulative - prev_cumulative
end

function M:_refresh_stars(star_count)
  if is_null(self._trans_star_list) or is_null(self._trans_star_item) then
    return
  end
  for _, go in ipairs(self._star_items) do
    UIUtil.destroy_go(go)
  end
  self._star_items = {}
  UIUtil.set_active(self._trans_star_item, false)
  for _ = 1, star_count do
    local go = GameObject.Instantiate(self._trans_star_item.gameObject, self._trans_star_list)
    UIUtil.set_active(go, true)
    table.insert(self._star_items, go)
  end
end

function M:_refresh_total(rare_data, curr_data, rank)
  local score = rare_data.total_add_score or 0
  if curr_data.Type == CodexDataType.Creature then
    local creature = curr_data.ServerData and curr_data.ServerData.Creature or nil
    local max_stars = creature ~= nil and creature.MaxStars or 0
    score = self:_get_creature_single_star_score(curr_data, max_stars, rank)
  end
  if not_null(self._txt_num_total) then
    UIUtil.set_text(self._txt_num_total, "+" .. score)
  end
  if not_null(self._txt_overall_rating) then
    UIUtil.set_text_by_id(self._txt_overall_rating, "CodexScore_Total")
  end
end

return M
