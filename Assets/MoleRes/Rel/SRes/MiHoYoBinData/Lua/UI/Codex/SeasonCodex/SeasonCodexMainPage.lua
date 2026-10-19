require("UI/Codex/SeasonCodex/CodexSeasonData")
local M = G.Class("SeasonCodexMainPage", G.UIWindow)
local base = G.UIWindow
local SeasonCodexItem = "UI/Codex/SeasonCodex/SeasonCodexItem"
local SeasonCodexFishTabItem = "UI/Codex/SeasonCodex/SeasonCodexFishTabItem"
local SeasonCodexTabItem = "UI/Codex/SeasonCodex/SeasonCodexTabItem"
local search_mixin = require("UI/Codex/Search/CodexSearchMixin")
local codex_anim = require("UI/Codex/SeasonCodex/SeasonCodexAnim")
local TabType = {
  Fish = codex_module.SeasonCategoryType.Fish,
  Insect = codex_module.SeasonCategoryType.Insect,
  Shore = codex_module.SeasonCategoryType.Shore
}
local SubTabType = {
  SeaFish = codex_module.SeasonFishSubType.SeaFish,
  RiverFish = codex_module.SeasonFishSubType.RiverFish
}
local FishSubTabDefines = {
  {
    sub = SubTabType.RiverFish,
    title = "Season_Codex_RiverFish",
    style_state = 0
  },
  {
    sub = SubTabType.SeaFish,
    title = "Season_Codex_SeaFish",
    style_state = 1
  }
}
local ITEM_GROUP_LIST_PATH = "main_container/anim_main/tab_contenet/item_group_list"

local function get_season_sort_key(data)
  if is_null(data) then
    return 0
  end
  local cfg = data.CodexCfg
  if is_null(cfg) then
    return 0
  end
  local season_index = cfg.seasoncollectionindex or 0
  return 0 < season_index and season_index or cfg.index or 0
end

local function compare_season_data(a, b)
  return get_season_sort_key(a) < get_season_sort_key(b)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/SeasonCodexMainPage"
  self.config.type = EUIType.Page
  self._is_close = false
  self._season_id = nil
  self._season_info = nil
  self._current_tab = TabType.Fish
  self._current_sub_tab = FishSubTabDefines[1].sub
  self._items = {}
  self._item_map = {}
  self._custom_layout = nil
  self._item_group_trans = nil
  self._season_pos_root = nil
  self._fish_tab_items = {}
  self._fish_tab_inited = false
  self._category_tab_items = {}
  self._category_tab_inited = false
  self._search_panel = nil
  self._search_panel_root = nil
end

function M:on_create()
  base.on_create(self)
  self:_init_custom_layout()
  self:_init_category_tabs()
  self:_add_ui_listener()
  self:_add_lua_evt_listener()
  search_mixin.ensure_search_panel(self, function()
    return {
      type = CodexDataType.Creature,
      include_package = false
    }
  end)
  if self._search_panel then
    self._search_panel:set_outside_click_callback(function(panel)
      panel:collapse()
    end)
    self._search_panel:set_field_state_callback(function(_is_open)
      self:_on_search_field_state_changed(_is_open)
    end)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_init_fish_tabs()
  self._is_close = false
  if not self:_apply_season_id() then
    return
  end
  self:_refresh_all()
end

function M:on_disable()
  base.on_disable(self)
  self:_close_search_panel(true)
end

function M:on_destroy()
  base.on_destroy(self)
  self:_remove_lua_evt_listener()
  self:_clear_category_tabs()
  self:_clear_fish_tabs()
  self:_clear_items()
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_on_btn_fullscreen()
  self:_close_search_panel()
end

function M:_close_search_panel(silent)
  search_mixin.close_search_panel(self, silent)
end

function M:_on_search_field_state_changed(_is_open)
  if not_null(self._btn_fullscreen) then
    UIUtil.set_active(self._btn_fullscreen, false)
  end
end

function M:_init_custom_layout()
  local clg = self._custom_layout_group
  self._custom_layout = clg
  if not is_null(clg) then
    self._item_group_trans = clg.transform
    return
  end
  if not is_null(self.game_obj) then
    local found = self.game_obj.transform:Find(ITEM_GROUP_LIST_PATH)
    if not is_null(found) then
      self._item_group_trans = found
    end
  end
end

function M:_init_category_tabs()
  if self._category_tab_inited then
    return
  end
  if is_null(self._trans_tab_left_group) or is_null(self._tog_category_1) then
    return
  end
  local template_go = self._tog_category_1.gameObject
  local red_point_template = self:_get_category_red_point_template()
  local tab_cfgs = codex_module:get_season_category_tab_cfgs()
  for _, cfg in ipairs(tab_cfgs) do
    local go = UIUtil.load_prefab_set_parent(template_go, self._trans_tab_left_group)
    if not is_null(go) then
      go.name = "category_tab_" .. tostring(cfg.category)
      local item = self:add_panel(SeasonCodexTabItem, go.transform)
      item:setup(cfg.category, cfg.icon_path, pack(self, M._on_tab_click), red_point_template)
      self._category_tab_items[cfg.category] = item
    end
  end
  UIUtil.set_active(self._tog_category_1, false)
  self._category_tab_inited = true
end

function M:_get_category_red_point_template()
  if is_null(self._trans_fish_tab) then
    return nil
  end
  return self._trans_fish_tab:GetComponentInChildren(typeof(MonoRedPointContainer), true)
end

function M:_clear_category_tabs()
  for _, item in pairs(self._category_tab_items) do
    if item ~= nil then
      self:remove_panel(item)
    end
  end
  self._category_tab_items = {}
  self._category_tab_inited = false
end

function M:_refresh_category_tabs()
  for category, item in pairs(self._category_tab_items) do
    if item ~= nil then
      item:set_selected(self._current_tab == category)
      item:refresh_red_point(self:_has_category_new(category))
    end
  end
end

function M:_has_category_new(category)
  local list = self._season_info and self._season_info.category_data[category] or {}
  for _, data in ipairs(list) do
    if data.IsUnlocked then
      local id = data.IdCfg and data.IdCfg.id or 0
      if codex_module:is_season_new_item(id) then
        return true
      end
    end
  end
  return false
end

function M:_init_fish_tabs()
  if self._fish_tab_inited then
    return
  end
  Logger.Log("_init_fish_tabs")
  if is_null(self._trans_fish_tabs_root) or is_null(self._trans_fish_tab) then
    return
  end
  for _, def in ipairs(FishSubTabDefines) do
    local trans = self._trans_fish_tabs_root:AddChildFromPrefab(self._trans_fish_tab)
    if not is_null(trans) then
      trans.name = "fish_tab_" .. tostring(def.sub)
      local item = self:add_panel(SeasonCodexFishTabItem, trans)
      item:setup(def.sub, def.title, def.style_state, pack(self, M._on_sub_tab_click))
      self._fish_tab_items[def.sub] = item
    end
  end
  UIUtil.set_active(self._trans_fish_tab, false)
  self._fish_tab_inited = true
end

function M:_clear_fish_tabs()
  for _, item in pairs(self._fish_tab_items) do
    if item ~= nil then
      self:remove_panel(item)
    end
  end
  self._fish_tab_items = {}
  self._fish_tab_inited = false
end

function M:_refresh_fish_tabs()
  local show = self._current_tab == TabType.Fish
  if not_null(self._trans_tab_contenet_fish) then
    UIUtil.set_active(self._trans_tab_contenet_fish, show)
  end
  if not_null(self._trans_fish_tabs_root) then
    UIUtil.set_active(self._trans_fish_tabs_root, show)
  end
  if not show then
    return
  end
  local fish_list = self._season_info and self._season_info.category_data[TabType.Fish] or {}
  for _, def in ipairs(FishSubTabDefines) do
    local item = self._fish_tab_items[def.sub]
    if item ~= nil then
      local unlocked, total, has_new = self:_count_fish_sub(fish_list, def.sub)
      item:refresh_num(unlocked, total)
      item:refresh_red_point(has_new)
      item:set_selected(self._current_sub_tab == def.sub)
    end
  end
end

function M:_count_fish_sub(fish_list, fish_sub)
  local total = 0
  local unlocked = 0
  local has_new = false
  for _, data in ipairs(fish_list) do
    local matched = fish_sub == SubTabType.SeaFish and codex_module:is_sea_fish(data) or fish_sub == SubTabType.RiverFish and codex_module:is_river_fish(data)
    if matched then
      total = total + 1
      if data.IsUnlocked then
        unlocked = unlocked + 1
        local id = data.IdCfg and data.IdCfg.id or 0
        if not has_new and codex_module:is_season_new_item(id) then
          has_new = true
        end
      end
    end
  end
  return unlocked, total, has_new
end

function M:_add_ui_listener()
  if not_null(self._img_close_btn) then
    self:bind_close_btn(self._img_close_btn)
  end
  if not_null(self._btn_reward) then
    self:bind_callback(self._btn_reward, pack(self, M._on_btn_reward_click))
  end
  if not_null(self._btn_fullscreen) then
    self:bind_callback(self._btn_fullscreen, pack(self, M._on_btn_fullscreen))
    UIUtil.set_active(self._btn_fullscreen, false)
  end
end

function M:_on_btn_reward_click()
  UIManagerInstance:open("UI/Codex/SeasonCodex/SeasonCodexPopup", {
    season_id = self._season_id,
    season_data_list = self:_get_season_all_data()
  })
end

function M:_add_lua_evt_listener()
  self._evt_codex_update = pack(self, M._on_codex_data_update)
  EventCenter.LuaAddListener(EventID.CodexDataUpdate, self._evt_codex_update)
  self._evt_season_reward_update = pack(self, M._refresh_progress)
  EventCenter.LuaAddListener(EventID.OnCodexSeasonNumRewardUpdate, self._evt_season_reward_update)
end

function M:_remove_lua_evt_listener()
  if self._evt_codex_update then
    EventCenter.LuaRemoveListener(EventID.CodexDataUpdate, self._evt_codex_update)
    self._evt_codex_update = nil
  end
  if self._evt_season_reward_update then
    EventCenter.LuaRemoveListener(EventID.OnCodexSeasonNumRewardUpdate, self._evt_season_reward_update)
    self._evt_season_reward_update = nil
  end
end

function M:_on_codex_data_update()
  if self._season_id == nil then
    return
  end
  self._season_info = codex_module:get_season_info(self._season_id)
  self:_refresh_all()
end

function M:_apply_season_id()
  local extra = self:get_extra_data() or {}
  local season_id = extra.season_id
  if season_id == nil or season_id == 0 then
    Logger.LogError("[SeasonCodex] 打开 SeasonCodexMainPage 必须传入有效 season_id，请检查调用方（如 UIManager:open(..., {season_id=xxx})）")
    self._season_id = nil
    self._season_info = nil
    return false
  end
  self._season_id = season_id
  self._season_info = codex_module:get_season_info(season_id)
  if self._season_info == nil then
    Logger.LogError("[SeasonCodex] 赛季 " .. tostring(season_id) .. " 无有效数据，无法展示")
    return false
  end
  return true
end

function M:_on_tab_click(tab_index)
  if self._current_tab == tab_index then
    return
  end
  self._current_tab = tab_index
  self._current_sub_tab = FishSubTabDefines[1].sub
  self:_refresh_tab_state()
  self:_refresh_items()
end

function M:_on_sub_tab_click(sub_index)
  if self._current_sub_tab == sub_index then
    return
  end
  self._current_sub_tab = sub_index
  self:_refresh_fish_tabs()
  self:_refresh_items()
end

function M:_refresh_all()
  self:_refresh_tab_state()
  self:_refresh_items()
  self:_refresh_progress()
end

function M:_refresh_tab_state()
  self:_refresh_category_tabs()
  self:_refresh_fish_tabs()
  self:_refresh_title_and_count()
end

function M:_refresh_title_and_count()
  if self._season_info == nil then
    return
  end
  local tab_name = ""
  local tab_cfgs = codex_module:get_season_category_tab_cfgs()
  for _, cfg in ipairs(tab_cfgs) do
    if cfg.category == self._current_tab then
      tab_name = cfg.name or ""
      break
    end
  end
  local title = UIUtil.get_text_by_id("SeasonCodex_Title")
  local season_cfg = ExcelDataUtil.get_value(typeof(BCodexSeasonSignCfg), self._season_id)
  if not_null(season_cfg) and not_null(season_cfg.seasoncodextitle) and season_cfg.seasoncodextitle ~= "" then
    title = season_cfg.seasoncodextitle
  end
  local has_split_title = not_null(self._txt_title) or not_null(self._txt_title1)
  if has_split_title then
    if not_null(self._txt_title) then
      UIUtil.set_text(self._txt_title, title)
    end
    if not_null(self._txt_title1) then
      UIUtil.set_text(self._txt_title1, tab_name)
    end
    if not_null(self._txt_tab_title) then
      UIUtil.set_active(self._txt_tab_title, false)
    end
  elseif not_null(self._txt_tab_title) then
    UIUtil.set_text(self._txt_tab_title, title .. "/" .. tab_name)
  end
  if not_null(self._txt_num_title) then
    local data_list = self:_get_filtered_data()
    local unlocked = 0
    for _, data in ipairs(data_list) do
      if data.IsUnlocked then
        unlocked = unlocked + 1
      end
    end
    UIUtil.set_text(self._txt_num_title, unlocked .. "/" .. #data_list)
  end
end

function M:_get_filtered_data()
  if self._season_info == nil then
    return {}
  end
  local list = self._season_info.category_data[self._current_tab] or {}
  if self._current_tab ~= TabType.Fish then
    return list
  end
  local filtered = {}
  for _, data in ipairs(list) do
    if self._current_sub_tab == SubTabType.SeaFish then
      if codex_module:is_sea_fish(data) then
        table.insert(filtered, data)
      end
    elseif codex_module:is_river_fish(data) then
      table.insert(filtered, data)
    end
  end
  return filtered
end

function M:_get_season_all_data()
  if self._season_id == nil then
    return {}
  end
  return codex_module:get_season_all_creatures(self._season_id)
end

local LegacyCategoryPosName = {
  [TabType.Fish] = "pos_group_fish",
  [TabType.Insect] = "pos_group_Insects",
  [TabType.Shore] = "pos_group_shore_dwellers"
}

function M:_current_pos_name()
  if self._current_tab == TabType.Fish then
    return codex_module:get_pos_name(TabType.Fish, self._current_sub_tab)
  end
  return codex_module:get_pos_name(self._current_tab, nil)
end

function M:_resolve_category_pos_root()
  if is_null(self._item_group_trans) then
    return nil
  end
  local pos_name = self:_current_pos_name()
  local season_root = self._season_pos_root
  if not is_null(season_root) and pos_name ~= nil then
    local pos_root = season_root:Find(pos_name)
    if not is_null(pos_root) then
      return pos_root
    end
    if self._current_tab == TabType.Fish and pos_name ~= "fish" then
      pos_root = season_root:Find("fish")
      if not is_null(pos_root) then
        return pos_root
      end
    end
  end
  local legacy_name = LegacyCategoryPosName[self._current_tab]
  if legacy_name ~= nil then
    local legacy = self._item_group_trans:Find(legacy_name)
    if not is_null(legacy) then
      return legacy
    end
  end
  Logger.LogWarning("[SeasonCodex] 赛季 " .. tostring(self._season_id) .. " 缺少分类位置组节点: pos_season_<id>/" .. tostring(pos_name) .. "，且旧版 " .. tostring(legacy_name) .. " 也不存在")
  return nil
end

function M:_apply_season_pos_root()
  if is_null(self._item_group_trans) then
    return false
  end
  local layout_key = codex_module:get_season_layout_key(self._season_id)
  local season_root = self._item_group_trans:Find(layout_key)
  if is_null(season_root) then
    self._season_pos_root = nil
    return true
  end
  self._season_pos_root = season_root
  return true
end

function M:_refresh_items()
  if not self:_apply_season_pos_root() then
    return
  end
  local pos_root = self:_resolve_category_pos_root()
  if is_null(pos_root) then
    return
  end
  self:_sync_layout_root_visible(pos_root)
  local item_group = pos_root:GetComponent(typeof(ItemGroup))
  self:_destroy_item_panels()
  if is_null(self._custom_layout) then
    return
  end
  self._custom_layout:SetPositionRoot(pos_root)
  if not is_null(item_group) then
    item_group:SetCaptureItemsActive(true)
  end
  local data_list = self:_get_filtered_data()
  table.sort(data_list, compare_season_data)
  local index_map = {}
  for i, data in ipairs(data_list) do
    index_map[i] = data
  end
  self._custom_layout:ReLoad(function(item, index)
    local data = index_map[index + 1]
    if is_null(data) then
      UIUtil.set_active(item, false)
      return
    end
    local instance_id = item:GetInstanceID()
    local cls = self:add_panel(SeasonCodexItem, item)
    self._item_map[instance_id] = cls
    table.insert(self._items, cls)
    cls:set_active(true)
    cls:refresh({
      data = data,
      index = index + 1,
      on_click = pack(self, M._on_item_click),
      on_new_cleared = pack(self, M._refresh_tab_red_points)
    })
    if not is_null(item_group) then
      local id = data.IdCfg and data.IdCfg.id or 0
      if id ~= 0 then
        item_group:ApplyOverride(item, id, false)
      end
    end
  end)
  if not is_null(item_group) then
    item_group:SetCaptureItemsActive(false)
  end
end

function M:_sync_layout_root_visible(pos_root)
  local function is_layout_root(trans)
    local n = trans.name
    
    return string.find(n, "pos_season_", 1, true) == 1 or string.find(n, "pos_group_", 1, true) == 1
  end
  
  local season_root = self._season_pos_root
  if not is_null(season_root) and not is_null(self._item_group_trans) then
    for i = 0, self._item_group_trans.childCount - 1 do
      local child = self._item_group_trans:GetChild(i)
      if is_layout_root(child) then
        UIUtil.set_active(child, child == season_root)
      end
    end
    for i = 0, season_root.childCount - 1 do
      local child = season_root:GetChild(i)
      UIUtil.set_active(child, child == pos_root)
    end
    return
  end
  if not is_null(self._item_group_trans) then
    for i = 0, self._item_group_trans.childCount - 1 do
      local child = self._item_group_trans:GetChild(i)
      if is_layout_root(child) then
        UIUtil.set_active(child, child == pos_root)
      end
    end
  end
end

function M:_refresh_tab_red_points()
  self:_refresh_category_tabs()
  if self._current_tab == TabType.Fish then
    local fish_list = self._season_info and self._season_info.category_data[TabType.Fish] or {}
    for _, def in ipairs(FishSubTabDefines) do
      local item = self._fish_tab_items[def.sub]
      if item ~= nil then
        local _, _, has_new = self:_count_fish_sub(fish_list, def.sub)
        item:refresh_red_point(has_new)
      end
    end
  end
end

function M:_destroy_item_panels()
  for _, cls in pairs(self._item_map) do
    if cls ~= nil then
      self:remove_panel(cls)
    end
  end
  self._items = {}
  self._item_map = {}
end

function M:_clear_items()
  self:_destroy_item_panels()
  if not is_null(self._custom_layout) then
    self._custom_layout:Clear()
  end
end

function M:_on_item_click(data)
  if is_null(data) then
    return
  end
  local strategy = codex_module:get_type_view_strategy(data.Type)
  UIManagerInstance:open(strategy:get_detail_page_class(), {
    item_id = data.IdCfg.id,
    enter_type = codex_module.codex_page_enter_type.codex_sub_type_list,
    navigation_item_ids = self:_get_navigation_item_ids()
  })
end

function M:_get_navigation_item_ids()
  local data_list = self:_get_filtered_data()
  table.sort(data_list, compare_season_data)
  local item_ids = {}
  for _, item_data in ipairs(data_list) do
    if not_null(item_data) and not_null(item_data.IdCfg) then
      table.insert(item_ids, item_data.IdCfg.id)
    end
  end
  return item_ids
end

function M:_refresh_progress()
  if self._season_id == nil then
    return
  end
  local unlocked, total = codex_module:get_season_unlocked_count(self._season_id)
  if not_null(self._txt_reward_label) then
    local reward_label = UIUtil.get_text_by_id("SeasonCodex_RewardLabel")
    local season_cfg = ExcelDataUtil.get_value(typeof(BCodexSeasonSignCfg), self._season_id)
    if not_null(season_cfg) and not_null(season_cfg.seasoncodexprogresstitle) and season_cfg.seasoncodexprogresstitle ~= "" then
      reward_label = season_cfg.seasoncodexprogresstitle
    end
    UIUtil.set_text(self._txt_reward_label, reward_label)
  end
  local next_node = codex_module:get_season_next_reward_node(self._season_id, unlocked)
  local target = next_node and next_node.count or total
  local progress = 0 < target and math.min(1, math.max(0, unlocked / target)) or 0
  self:_refresh_progress_fill(progress)
  if not_null(self._txt_reward_count) then
    UIUtil.set_text(self._txt_reward_count, unlocked .. "/" .. target)
  end
  self:_refresh_reward_btn_state()
end

function M:_refresh_progress_fill(progress)
  if is_null(self._trans_fill) then
    return
  end
  local width = self._trans_fill.rect.width
  local pos = self._trans_fill.anchoredPosition
  self._trans_fill.anchoredPosition = Vector2(-width * (1 - progress), pos.y)
end

function M:_refresh_reward_btn_state()
  local has_unclaimed, all_unlocked, all_claimed = codex_module:get_season_reward_summary_state(self._season_id)
  local state = 0
  if all_claimed then
    state = 1
  elseif all_unlocked and has_unclaimed then
    state = 2
  elseif has_unclaimed then
    state = 3
  end
  if not is_null(self._ui_state_group_reward) then
    self._ui_state_group_reward:SetState(state)
  end
  codex_anim.play(self._animator_helper_gift, codex_anim.giftpack, has_unclaimed and "claimable" or "idle")
  if not_null(self._red_point_reward) then
    self._red_point_reward:ShowRedPoint(codex_module:get_season_reward_red_point_type(self._season_id))
  end
end

return M
