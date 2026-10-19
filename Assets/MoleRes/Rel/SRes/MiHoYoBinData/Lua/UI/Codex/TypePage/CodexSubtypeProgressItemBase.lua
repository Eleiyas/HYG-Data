local M = G.Class("CodexSubtypeProgressItemBase", G.UIPanel)
local base = G.UIPanel
local progress_bar_panel_class = "UI/Codex/TypePage/CodexProgressBarPanel"
local progress_tips_item_class = "UI/Codex/TypePage/CodexProgressTipsItem"

function M:init()
  base.init(self)
  self._sub_type_info = nil
  self._sub_type_controller = nil
  self._view_strategy = nil
  self._item_count = 0
  self._unlocked_item_count = 0
  self._medal_cls = {}
  self._is_level_tips_showing = false
  self._level_tip_objs = {}
  self._level_tip_titles = {}
  self._level_tip_icons = {}
  self._level_tip_badges = {}
  self._level_tip_details = {}
  self._level_tip_ui_state_groups = {}
  self._progress_bar_panel = nil
  self._progress_tips_panel = nil
  self._is_progress_tips_showing = false
  self._progress_tips_cfg = nil
  self._progress_tips_creature_rd = nil
  self._progress_tips_tag_num_rd = nil
  self._icon_tips_panel = nil
  self._is_icon_tips_showing = false
  self._icon_tips_data = nil
  self._creature_tag_reward_list = nil
  self._is_expanded = false
end

function M:on_create()
  base.on_create(self)
  self:_init_progress_bar_panel()
  self:_init_progress_tips()
  self:_add_event_listener()
  self:_add_ui_listener()
  self:_init_level_tip_objs()
  self:_init_icon_tips()
end

function M:_init_progress_bar_panel()
  if is_null(self._trans_progress_bar) then
    return
  end
  self._progress_bar_panel = self:add_panel(progress_bar_panel_class, self._trans_progress_bar)
end

function M:_init_progress_tips()
  if is_null(self._trans_hide_progress_tips) then
    return
  end
  self._progress_tips_panel = self:add_panel(progress_tips_item_class, self._trans_hide_progress_tips)
  UIUtil.set_active(self._trans_hide_progress_tips, false)
end

function M:on_enable()
  base.on_enable(self)
  self._is_expanded = false
  self:_hide_level_tips()
  self:close_tips()
end

function M:on_disable()
  base.on_disable(self)
  self:collapse()
  self:_hide_level_tips()
  self:close_tips()
end

function M:on_destroy()
  if not_null(self._scroll_bar_rect) and self._scroll_value_changed_cb then
    self._scroll_bar_rect.onValueChanged:RemoveListener(self._scroll_value_changed_cb)
    self._scroll_value_changed_cb = nil
  end
  base.on_destroy(self)
end

function M:close_tips()
  self:_hide_level_tips()
  self:close_progress_tips()
  self:close_icon_tips()
  self:_notify_fullscreen_update()
end

function M:_add_event_listener()
  self:add_lua_listener(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, pack(self, M._refresh_progress))
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_progress, pack(self, M._on_btn_expand))
  self:bind_callback(self._btn_collapse, pack(self, M._on_btn_collapse))
  if not_null(self._scroll_bar_rect) then
    self._scroll_value_changed_cb = pack(self, M._on_scroll_value_changed)
    self._scroll_bar_rect.onValueChanged:AddListener(self._scroll_value_changed_cb)
  end
end

function M:_on_scroll_value_changed()
  self:close_progress_tips()
  self:close_icon_tips()
end

function M:_on_btn_expand()
  self:close_tips()
  self._is_expanded = true
  if not_null(self._ui_state_group_switch) then
    self._ui_state_group_switch:SetState(1)
  end
  if self.holder and self.holder.on_progress_expanded then
    self.holder:on_progress_expanded()
  end
  self:_notify_list_fullscreen()
  self:_scroll_to_first_claimable()
end

function M:_on_btn_collapse()
  self:close_tips()
  self._is_expanded = false
  if not_null(self._ui_state_group_switch) then
    self._ui_state_group_switch:SetState(0)
  end
  if self.holder and self.holder.on_progress_collapsed then
    self.holder:on_progress_collapsed()
  end
  self:_notify_list_fullscreen()
end

function M:collapse()
  if self._is_expanded then
    self:_on_btn_collapse()
  end
end

function M:_notify_fullscreen_update()
  if self.holder and self.holder._update_fullscreen_visible then
    self.holder:_update_fullscreen_visible()
  end
end

function M:_notify_list_fullscreen()
  local list_ctl = self.holder and self.holder._sub_type_list_ctl
  if list_ctl and list_ctl._update_fullscreen_close_visible then
    list_ctl:_update_fullscreen_close_visible()
  end
end

function M:refresh(sub_type_info, view_strategy, sub_type_controller, type_ctrl)
  self:close_tips()
  self._sub_type_info = sub_type_info
  self._view_strategy = view_strategy
  self._sub_type_controller = sub_type_controller
  self._type_ctrl = type_ctrl
  if not self._sub_type_controller then
    return
  end
  self:_refresh_progress_title()
  self:_refresh_rank_group()
  self:_refresh_progress()
  self:_refresh_level_tips()
end

function M:_refresh_progress_title()
  local key = self._view_strategy and self._view_strategy:get_progress_title_key(self._sub_type_info)
  if not key then
    return
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, key)
  end
  if not_null(self._txt_title_expand) then
    UIUtil.set_text_by_id(self._txt_title_expand, key)
  end
end

function M:_refresh_rank_group()
  if is_null(self._trans_rank_group) then
    return
  end
  local show_medals = self._view_strategy and self._view_strategy:has_medals(self._sub_type_controller) or false
  if not show_medals then
    UIUtil.set_active(self._trans_rank_group, false)
    return
  end
  UIUtil.set_active(self._trans_rank_group, true)
  local statics = self._sub_type_controller:get_highest_medal_statics()
  for i = #statics, 1, -1 do
    local cls = self._medal_cls[#statics - i + 1]
    if cls == nil then
      local medal_obj = UIUtil.load_prefab_set_parent(self._trans_medal, self._trans_rank_group)
      if not_null(medal_obj) then
        cls = codex_module:init_medal_comp(medal_obj.transform)
        table.insert(self._medal_cls, cls)
      end
    end
    codex_module:set_medal_comp(cls, i, i == #statics, statics[i], self:get_load_proxy())
    UIUtil.set_active(cls.trans, true)
  end
  for i = #statics + 1, #self._medal_cls do
    UIUtil.set_active(self._medal_cls[i].trans, false)
  end
end

function M:_set_progress_text(current, total)
  local ns, ts
  if self._type_ctrl and self._type_ctrl.type == CodexDataType.Cloth then
    ns, ts = 40, 30
  else
    ns, ts = 50, 26
  end
  local text = string.format("%d/%d", current, total)
  if not_null(self._txt_progress_num) then
    UIUtil.set_text(self._txt_progress_num, text)
  end
  if not_null(self._txt_progress_num_expand) then
    UIUtil.set_text(self._txt_progress_num_expand, text)
  end
  if not_null(self._txt_num_expand) then
    UIUtil.set_text(self._txt_num_expand, text)
  end
end

function M:_refresh_progress()
  local use_global = self._view_strategy and self._view_strategy.use_global_progress and self._view_strategy:use_global_progress()
  local count_source = use_global and self._type_ctrl or self._sub_type_controller
  self._item_count = math.max(0, count_source:get_item_count())
  self._unlocked_item_count = math.max(0, count_source:get_unlocked_item_count())
  self._creature_tag_reward_list = nil
  self._tag_num_reward_list = nil
  local progress_style = self._view_strategy and self._view_strategy:get_progress_style(self._sub_type_controller) or "standard"
  if progress_style == "creature_tag" then
    local sub_type_cfg = self._sub_type_controller:get_sub_type_cfg()
    local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
    if tag then
      local cs_list = CsCodexModuleUtil.GetCreatureTagNumRewardListByTag(tag)
      if not_null(cs_list) and 0 < cs_list.Count then
        self._creature_tag_reward_list = {}
        local current_count = cs_list[0].CurrentCount
        for i = 0, cs_list.Count - 1 do
          table.insert(self._creature_tag_reward_list, cs_list[i])
        end
        local next_threshold = self:_get_next_reward_threshold(current_count)
        self:_set_progress_text(current_count, next_threshold)
        local progress = self._item_count > 0 and current_count / self._item_count or 0
        progress = math.min(1, math.max(0, progress))
        if self._progress_bar_panel then
          self._progress_bar_panel:set_slider_value(progress)
          self._progress_bar_panel:set_creature_tag_steps(self._creature_tag_reward_list, self._item_count, current_count)
        end
        self:_set_next_lv_num_creature(current_count)
        self:_refresh_outer_icon()
        self:_refresh_red_point()
        self:_scroll_to_first_claimable()
        return
      end
    end
  elseif progress_style == "tag_num" then
    local reward_type = self._view_strategy and self._view_strategy:get_tag_num_reward_type() or nil
    local tag
    if reward_type == codex_module.TagNumRewardType.PerTab then
      local sub_type_cfg = self._sub_type_controller:get_sub_type_cfg()
      tag = sub_type_cfg and sub_type_cfg.contenttag or nil
    else
      local maintype = self._type_ctrl and self._type_ctrl.type or nil
      tag = maintype and codex_module:get_main_tag(maintype) or nil
    end
    if tag then
      local cs_list = CsCodexModuleUtil.GetTagNumRewardListByTag(tag)
      if not_null(cs_list) and 0 < cs_list.Count then
        self._tag_num_reward_list = {}
        for i = 0, cs_list.Count - 1 do
          table.insert(self._tag_num_reward_list, cs_list[i])
        end
        local next_threshold = self:_get_next_reward_threshold()
        self:_set_progress_text(self._unlocked_item_count, next_threshold)
        local progress = self._item_count > 0 and self._unlocked_item_count / self._item_count or 0
        progress = math.min(1, math.max(0, progress))
        if self._progress_bar_panel then
          self._progress_bar_panel:set_slider_value(progress)
          local show_map = self._progress_bar_panel:build_tag_num_show_map(tag, reward_type)
          self._progress_bar_panel:set_tag_num_steps(self._tag_num_reward_list, self._item_count, self._unlocked_item_count, show_map)
        end
        self:_set_next_lv_num()
        self:_refresh_outer_icon()
        self:_refresh_red_point()
        self:_scroll_to_first_claimable()
        return
      end
    end
  end
  local next_threshold = self:_get_next_reward_threshold()
  self:_set_progress_text(self._unlocked_item_count, next_threshold)
  local progress = self._item_count > 0 and self._unlocked_item_count / self._item_count or 0
  progress = math.min(1, math.max(0, progress))
  if self._progress_bar_panel then
    self._progress_bar_panel:set_slider_value(progress)
    local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
    local reward_type = self._view_strategy and self._view_strategy:get_tag_num_reward_type() or nil
    self._progress_bar_panel:set_steps(level_cfgs, self._item_count, self._unlocked_item_count, reward_type)
  end
  self:_set_next_lv_num()
  self:_refresh_outer_icon()
  self:_refresh_red_point()
  self:_scroll_to_first_claimable()
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  local show_type, _ = self:_get_first_claimable_reward_show_type()
  local rp_type = show_type and RedPointType.GiftRP or RedPointType.None
  self._red_point:ShowRedPoint(rp_type)
end

function M:_scroll_to_first_claimable()
  if is_null(self._scroll_bar_rect) then
    return
  end
  local bar_panel = self._progress_bar_panel
  if not bar_panel then
    return
  end
  local claimable_num = self:find_first_claimable_num_for_scroll()
  if not claimable_num then
    return
  end
  local item_count = self._item_count
  if not item_count or item_count <= 0 then
    return
  end
  local bar_width = bar_panel:get_bar_width()
  if not bar_width or bar_width <= 0 then
    return
  end
  local sr = self._scroll_bar_rect
  local vp = sr.viewport
  if is_null(vp) then
    return
  end
  local viewport_width = vp.rect.width
  if viewport_width <= 0 or bar_width <= viewport_width then
    return
  end
  local ratio = math.max(0, math.min(1, claimable_num / item_count))
  local target_x = ratio * bar_width
  local denom = bar_width - viewport_width
  if denom <= 0 then
    return
  end
  local scroll_n = (target_x - viewport_width * 0.5) / denom
  scroll_n = math.max(0, math.min(1, scroll_n))
  if sr.horizontal then
    sr.horizontalNormalizedPosition = scroll_n
  elseif sr.vertical then
    sr.verticalNormalizedPosition = 1 - scroll_n
  end
end

function M:_set_next_lv_num()
  if is_null(self._trans_txt_nextlv) or is_null(self._trans_txt_nextlv_num) then
    return
  end
  if not self._view_strategy or not self._view_strategy:has_sub_type_badge() then
    UIUtil.set_active(self._trans_txt_nextlv, false)
    UIUtil.set_active(self._trans_txt_nextlv_num, false)
    return
  end
  local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
  local level = 1
  while level <= #level_cfgs and self._unlocked_item_count >= level_cfgs[level].num do
    level = level + 1
  end
  if not level_cfgs[level] then
    UIUtil.set_active(self._trans_txt_nextlv, false)
    UIUtil.set_active(self._trans_txt_nextlv_num, false)
    return
  end
  local nextlv_count = level_cfgs[level].num
  UIUtil.set_text(self._txt_nextlv_num, nextlv_count)
  UIUtil.set_active(self._trans_txt_nextlv, true)
  UIUtil.set_active(self._trans_txt_nextlv_num, true)
end

function M:_set_next_lv_num_creature(current_count)
  if is_null(self._trans_txt_nextlv) or is_null(self._trans_txt_nextlv_num) then
    return
  end
  local reward_list = self._creature_tag_reward_list
  if not reward_list or #reward_list == 0 then
    UIUtil.set_active(self._trans_txt_nextlv, false)
    UIUtil.set_active(self._trans_txt_nextlv_num, false)
    return
  end
  local next_target
  for _, reward_data in ipairs(reward_list) do
    if current_count < reward_data.CreatureNum then
      next_target = reward_data.CreatureNum
      break
    end
  end
  if not next_target then
    UIUtil.set_active(self._trans_txt_nextlv, false)
    UIUtil.set_active(self._trans_txt_nextlv_num, false)
    return
  end
  UIUtil.set_text(self._txt_nextlv_num, next_target)
  UIUtil.set_active(self._trans_txt_nextlv, true)
  UIUtil.set_active(self._trans_txt_nextlv_num, true)
end

function M:_refresh_level_tips()
  if not_null(self._trans_badge) then
    local show_badge = self._view_strategy == nil or self._view_strategy:has_sub_type_badge()
    UIUtil.set_active(self._trans_badge, show_badge)
  end
  self:_hide_level_tips()
  local cfg = self._sub_type_controller:get_curr_level_cfg()
  if not_null(cfg) then
    if not_null(self._img_medal) then
      UIUtil.set_image(self._img_medal, cfg.badgeicon, self:get_load_proxy())
    end
    if not_null(self._img_sub_type_icon) then
      UIUtil.set_image(self._img_sub_type_icon, cfg.typeicon, self:get_load_proxy())
    end
    if not_null(self._img_icon_expand) then
      UIUtil.set_image(self._img_icon_expand, cfg.typeicon, self:get_load_proxy())
    end
  else
    local sub_type_cfg = self._sub_type_controller:get_sub_type_cfg()
    local fallback_icon = not_null(sub_type_cfg) and sub_type_cfg.icon or nil
    if fallback_icon and fallback_icon ~= "" then
      if not_null(self._img_sub_type_icon) then
        UIUtil.set_image(self._img_sub_type_icon, fallback_icon, self:get_load_proxy())
      end
      if not_null(self._img_icon_expand) then
        UIUtil.set_image(self._img_icon_expand, fallback_icon, self:get_load_proxy())
      end
    end
  end
end

function M:_init_level_tip_objs()
  if not_null(self._trans_level_group_a) then
    self:_init_one_level_tip_obj(self._trans_level_group_a)
  end
  if not_null(self._trans_level_group_b) then
    self:_init_one_level_tip_obj(self._trans_level_group_b)
  end
  if not_null(self._trans_level_group_c) then
    self:_init_one_level_tip_obj(self._trans_level_group_c)
  end
end

function M:_init_one_level_tip_obj(obj_trans)
  table.insert(self._level_tip_objs, obj_trans)
  local title_text = UIUtil.find_cmpt(obj_trans, "txt_group/title_group/txt_title", typeof(TextEx))
  local detail_text = UIUtil.find_cmpt(obj_trans, "txt_group/txt_detail", typeof(TextEx))
  local icon_img = UIUtil.find_cmpt(obj_trans, "obj_badge/Icon", typeof(ImageEx))
  local icon_badge = UIUtil.find_cmpt(obj_trans, "obj_badge/bg", typeof(ImageEx))
  local ui_state_group = UIUtil.find_cmpt(obj_trans, "ui_state_group_complete", typeof(UIStateChangeGroup))
  table.insert(self._level_tip_titles, title_text)
  table.insert(self._level_tip_details, detail_text)
  table.insert(self._level_tip_icons, icon_img)
  table.insert(self._level_tip_badges, icon_badge)
  table.insert(self._level_tip_ui_state_groups, ui_state_group)
end

function M:_show_level_tips()
  if self._is_level_tips_showing then
    return
  end
  local unlock_cfgs = self._sub_type_controller:get_unlock_cfgs()
  if is_null(unlock_cfgs) then
    return
  end
  local unlocked_item_count = self._sub_type_controller:get_unlocked_item_count()
  local data = {
    cfgs = unlock_cfgs,
    unlocked_item_count = unlocked_item_count,
    sub_type_id = self._sub_type_info and self._sub_type_info.sub_type_id or nil
  }
  UIManagerInstance:open("UI/Codex/TypePage/CodexSubTypeProgressPreviewDialog", data)
end

function M:_hide_level_tips()
  self._is_level_tips_showing = false
  if not_null(self._trans_detail_tips) then
    UIUtil.set_active(self._trans_detail_tips, false)
  end
end

function M:toggle_progress_tips(cfg, anchor_rect)
  if self._is_progress_tips_showing and self._progress_tips_cfg == cfg then
    self:_close_progress_tips()
  else
    self:_show_progress_tips(cfg, anchor_rect)
  end
end

function M:toggle_tag_num_reward_tips(reward_data, anchor_rect)
  if self._is_progress_tips_showing and self._progress_tips_tag_num_rd == reward_data then
    self:_close_progress_tips()
  else
    self:_show_tag_num_reward_tips(reward_data, anchor_rect)
  end
end

function M:toggle_creature_tag_reward_tips(reward_data, anchor_rect)
  if self._is_progress_tips_showing and self._progress_tips_creature_rd == reward_data then
    self:_close_progress_tips()
  else
    self:_show_creature_tag_reward_tips(reward_data, anchor_rect)
  end
end

function M:toggle_icon_reward_tips(data, anchor_rect)
  if self._is_icon_tips_showing and self._icon_tips_data == data then
    self:close_icon_tips()
  else
    self:_show_icon_reward_tips(data, anchor_rect)
  end
end

function M:_show_progress_tips(cfg, anchor_rect)
  self:close_icon_tips()
  if is_null(self._trans_hide_progress_tips) or not self._progress_tips_panel then
    return
  end
  self._is_progress_tips_showing = true
  self._progress_tips_cfg = cfg
  self._progress_tips_creature_rd = nil
  self._progress_tips_tag_num_rd = nil
  self:_align_progress_tips_x(anchor_rect)
  self._progress_tips_panel:refresh(cfg, self._unlocked_item_count)
  UIUtil.set_active(self._trans_hide_progress_tips, true)
  if self.holder and self.holder.show_fullscreen_close then
    self.holder:show_fullscreen_close()
  end
end

function M:_show_tag_num_reward_tips(reward_data, anchor_rect)
  self:close_icon_tips()
  if is_null(self._trans_hide_progress_tips) or not self._progress_tips_panel then
    return
  end
  self._is_progress_tips_showing = true
  self._progress_tips_cfg = nil
  self._progress_tips_creature_rd = nil
  self._progress_tips_tag_num_rd = reward_data
  self:_align_progress_tips_x(anchor_rect)
  self._progress_tips_panel:refresh_tag_num(reward_data)
  UIUtil.set_active(self._trans_hide_progress_tips, true)
  if self.holder and self.holder.show_fullscreen_close then
    self.holder:show_fullscreen_close()
  end
end

function M:_show_creature_tag_reward_tips(reward_data, anchor_rect)
  self:close_icon_tips()
  if is_null(self._trans_hide_progress_tips) or not self._progress_tips_panel then
    return
  end
  self._is_progress_tips_showing = true
  self._progress_tips_cfg = nil
  self._progress_tips_creature_rd = reward_data
  self._progress_tips_tag_num_rd = nil
  self:_align_progress_tips_x(anchor_rect)
  self._progress_tips_panel:refresh_creature_tag(reward_data)
  UIUtil.set_active(self._trans_hide_progress_tips, true)
  if self.holder and self.holder.show_fullscreen_close then
    self.holder:show_fullscreen_close()
  end
end

function M:_align_progress_tips_x(anchor_rect)
  local world_pos = anchor_rect.position
  local tips_trans = self._trans_hide_progress_tips
  local tips_parent = tips_trans.parent
  local local_pos = tips_parent:InverseTransformPoint(world_pos)
  local cur = tips_trans.localPosition
  tips_trans.localPosition = Vector3(local_pos.x, cur.y, cur.z)
end

function M:close_progress_tips()
  self._is_progress_tips_showing = false
  self._progress_tips_cfg = nil
  self._progress_tips_creature_rd = nil
  self._progress_tips_tag_num_rd = nil
  if not_null(self._trans_hide_progress_tips) then
    UIUtil.set_active(self._trans_hide_progress_tips, false)
  end
end

function M:_close_progress_tips()
  self:close_progress_tips()
  self:_notify_fullscreen_update()
end

function M:_init_icon_tips()
  if is_null(self._trans_hide_progress_icon_tips) then
    return
  end
  self._icon_tips_panel = self:add_panel(progress_tips_item_class, self._trans_hide_progress_icon_tips)
  if self._icon_tips_panel.set_icon_tips_mode then
    self._icon_tips_panel:set_icon_tips_mode(true)
  end
  UIUtil.set_active(self._trans_hide_progress_icon_tips, false)
end

function M:close_icon_tips()
  self._is_icon_tips_showing = false
  self._icon_tips_data = nil
  if not_null(self._trans_hide_progress_icon_tips) then
    UIUtil.set_active(self._trans_hide_progress_icon_tips, false)
  end
  self:_notify_fullscreen_update()
end

function M:_show_icon_reward_tips(data, anchor_rect)
  self:close_progress_tips()
  if is_null(self._trans_hide_progress_icon_tips) or not self._icon_tips_panel then
    return
  end
  self._is_icon_tips_showing = true
  self._icon_tips_data = data
  self:_align_icon_tips_x(anchor_rect)
  local pic = self:_get_special_reward_pic_for_data(data)
  if self._creature_tag_reward_list then
    self._icon_tips_panel:refresh_creature_tag(data)
  elseif self._tag_num_reward_list then
    self._icon_tips_panel:refresh_tag_num(data)
  else
    self._icon_tips_panel:refresh(data, self._unlocked_item_count)
  end
  if pic and pic ~= "" then
    self._icon_tips_panel:set_special_reward_pic(pic)
  end
  UIUtil.set_active(self._trans_hide_progress_icon_tips, true)
  if self.holder and self.holder.show_fullscreen_close then
    self.holder:show_fullscreen_close()
  end
end

function M:_align_icon_tips_x(anchor_rect)
  local world_pos = anchor_rect.position
  local tips_trans = self._trans_hide_progress_icon_tips
  local tips_parent = tips_trans.parent
  local local_pos = tips_parent:InverseTransformPoint(world_pos)
  local cur = tips_trans.localPosition
  tips_trans.localPosition = Vector3(local_pos.x, cur.y, cur.z)
end

function M:_get_special_reward_pic_for_data(data)
  if not data then
    return nil
  end
  if data.ConfigId then
    local row_t = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), data.ConfigId)
    if not is_null(row_t) and row_t.specialrewardpic and row_t.specialrewardpic ~= "" then
      return row_t.specialrewardpic
    end
    local row = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), data.ConfigId)
    if not is_null(row) and row.specialrewardpic and row.specialrewardpic ~= "" then
      return row.specialrewardpic
    end
  end
  if data.subtype and data.num then
    local row = self:_find_tag_num_cfg_row_for_subtype_num(data.num)
    if not is_null(row) and row.specialrewardpic and row.specialrewardpic ~= "" then
      return row.specialrewardpic
    end
  end
  return nil
end

function M:_find_tag_num_cfg_row_for_subtype_num(num)
  local st = self._sub_type_controller and self._sub_type_controller:get_sub_type_cfg()
  local tag = st and st.contenttag
  if not tag or tag == "" then
    return nil
  end
  local reward_type = self._view_strategy and self._view_strategy:get_tag_num_reward_type() or nil
  local all_rows = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg))
  if not all_rows then
    return nil
  end
  for _, row in pairs(all_rows) do
    if not is_null(row) and row.tag == tag and row.num == num and (reward_type == nil or row.type == nil or row.type == reward_type) then
      return row
    end
  end
  return nil
end

function M:toggle_gift_tips(package_data, anchor_trans)
end

function M:_refresh_outer_icon()
  if is_null(self._trans_icon) then
    return
  end
  local reward_data, cfg_row = self:_get_last_show_type2_reward_data()
  if reward_data and not_null(self._img_icon_dynamic) then
    if self:_try_set_outer_icon_from_rewards(reward_data.Rewards) then
      return
    end
    if cfg_row and self:_try_set_outer_icon_from_pool(cfg_row.randompoolid) then
      return
    end
  end
  UIUtil.set_active(self._trans_icon, true)
  if not_null(self._img_icon_dynamic) then
    UIUtil.set_active(self._img_icon_dynamic, false)
  end
end

function M:_try_set_outer_icon_from_rewards(rewards)
  if not_null(rewards) and not_null(rewards.RewardItemList) and rewards.RewardItemList.Count > 0 then
    local first = rewards.RewardItemList[0]
    local item_cfg = item_module:get_cfg_by_id(first.ItemConfigId)
    if item_cfg then
      UIUtil.set_active(self._img_icon_dynamic, true)
      item_module:set_item_icon(self._img_icon_dynamic, 0, item_cfg, nil, self:get_load_proxy())
      UIUtil.set_active(self._trans_icon, false)
      return true
    end
  end
  return false
end

function M:_try_set_outer_icon_from_pool(pool_id)
  if not pool_id or pool_id <= 0 then
    return false
  end
  local pool_entries = ExcelDataUtil.get_value(typeof(BRandomPoolCfg), pool_id)
  if is_null(pool_entries) then
    return false
  end
  local entries = list_to_table(pool_entries)
  local first
  for _, entry in ipairs(entries) do
    if not is_null(entry) and entry.configid and 0 < entry.configid then
      first = entry
      break
    end
  end
  if not (first and first.configid) or 0 >= first.configid then
    return false
  end
  local item_cfg = item_module:get_cfg_by_id(first.configid)
  if item_cfg then
    UIUtil.set_active(self._img_icon_dynamic, true)
    item_module:set_item_icon(self._img_icon_dynamic, 0, item_cfg, nil, self:get_load_proxy())
    UIUtil.set_active(self._trans_icon, false)
    return true
  end
  return false
end

function M:_get_last_show_type2_reward_data()
  if self._tag_num_reward_list then
    for i = #self._tag_num_reward_list, 1, -1 do
      local rd = self._tag_num_reward_list[i]
      local row = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), rd.ConfigId)
      if not is_null(row) and row.rewardshowtype == 2 then
        return rd, row
      end
    end
  elseif self._creature_tag_reward_list then
    for i = #self._creature_tag_reward_list, 1, -1 do
      local rd = self._creature_tag_reward_list[i]
      local row = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), rd.ConfigId)
      if not is_null(row) and row.rewardshowtype == 2 then
        return rd, row
      end
    end
  else
    local level_cfgs = self._sub_type_controller and self._sub_type_controller:get_unlock_cfgs()
    local st_cfg = self._sub_type_controller and self._sub_type_controller:get_sub_type_cfg()
    local sub_type_id = st_cfg and st_cfg.subtype
    if level_cfgs and sub_type_id then
      for i = #level_cfgs, 1, -1 do
        local cfg = level_cfgs[i]
        local row = self:_find_tag_num_cfg_row_for_subtype_num(cfg.num)
        if not is_null(row) and row.rewardshowtype == 2 then
          local rd = CsCodexModuleUtil.GetSubTypeLevelRewardData(sub_type_id, cfg.level)
          if not_null(rd) then
            return rd, row
          end
        end
      end
    end
  end
  return nil, nil
end

function M:_get_first_claimable_reward_show_type()
  if self._tag_num_reward_list then
    for _, rd in ipairs(self._tag_num_reward_list) do
      if rd.IsUnlocked and not rd.IsRewardTaken then
        local row = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), rd.ConfigId)
        local st = not is_null(row) and row.rewardshowtype or 0
        return st, rd
      end
    end
  elseif self._creature_tag_reward_list then
    for _, rd in ipairs(self._creature_tag_reward_list) do
      if rd.IsUnlocked and not rd.IsRewardTaken then
        local row = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), rd.ConfigId)
        local st = not is_null(row) and row.rewardshowtype or 0
        return st, rd
      end
    end
  else
    local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
    local st_cfg = self._sub_type_controller:get_sub_type_cfg()
    local sub_type_id = st_cfg and st_cfg.subtype
    if level_cfgs and sub_type_id then
      for _, cfg in ipairs(level_cfgs) do
        if self._unlocked_item_count >= cfg.num then
          local reward_data = CsCodexModuleUtil.GetSubTypeLevelRewardData(sub_type_id, cfg.level)
          if not_null(reward_data) and not reward_data.IsRewardsTaken then
            local row = self:_find_tag_num_cfg_row_for_subtype_num(cfg.num)
            local st = not is_null(row) and row.rewardshowtype or 0
            return st, reward_data
          end
        end
      end
    end
  end
  return nil, nil
end

function M:find_first_claimable_num_for_scroll()
  local first_unreached
  if self._tag_num_reward_list then
    for _, rd in ipairs(self._tag_num_reward_list) do
      if rd.IsUnlocked and not rd.IsRewardTaken then
        return rd.Num
      end
      if not first_unreached and not rd.IsUnlocked then
        first_unreached = rd.Num
      end
    end
  elseif self._creature_tag_reward_list then
    for _, rd in ipairs(self._creature_tag_reward_list) do
      if rd.IsUnlocked and not rd.IsRewardTaken then
        return rd.CreatureNum
      end
      if not first_unreached and not rd.IsUnlocked then
        first_unreached = rd.CreatureNum
      end
    end
  else
    local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
    local st_cfg = self._sub_type_controller:get_sub_type_cfg()
    local sub_type_id = st_cfg and st_cfg.subtype
    if level_cfgs and sub_type_id then
      for _, cfg in ipairs(level_cfgs) do
        if self._unlocked_item_count >= cfg.num then
          local reward_data = CsCodexModuleUtil.GetSubTypeLevelRewardData(sub_type_id, cfg.level)
          if not_null(reward_data) and not reward_data.IsRewardsTaken then
            return cfg.num
          end
        else
          first_unreached = first_unreached or cfg.num
        end
      end
    end
  end
  return first_unreached or self._unlocked_item_count
end

function M:claim_all_progress_rewards()
  if self._creature_tag_reward_list then
    self:_claim_all_creature_tag_rewards()
    return
  end
  if self._tag_num_reward_list then
    self:_claim_all_tag_num_rewards()
    return
  end
  local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
  if not level_cfgs then
    return
  end
  local sub_type_cfg = self._sub_type_controller:get_sub_type_cfg()
  local sub_type_id = sub_type_cfg and sub_type_cfg.subtype or nil
  if not sub_type_id then
    return
  end
  local unlocked = self._unlocked_item_count
  local claimable_levels = {}
  local level_rewards = {}
  for _, cfg in ipairs(level_cfgs) do
    local reward_data = CsCodexModuleUtil.GetSubTypeLevelRewardData(sub_type_id, cfg.level)
    if unlocked >= cfg.num and not_null(reward_data) and not reward_data.IsRewardsTaken then
      table.insert(claimable_levels, cfg)
      local rewards = {}
      if reward_data.Rewards and reward_data.Rewards.RewardItemList then
        for i = 0, reward_data.Rewards.RewardItemList.Count - 1 do
          local item = reward_data.Rewards.RewardItemList[i]
          table.insert(rewards, {
            id = item.ItemConfigId,
            num = item.Count
          })
        end
      end
      level_rewards[cfg.level] = rewards
    end
  end
  if #claimable_levels == 0 then
    return
  end
  local pending = #claimable_levels
  local success_rewards = {}
  for _, cfg in ipairs(claimable_levels) do
    CsCodexModuleUtil.GetCodexTakeSubTypeReward(sub_type_id, cfg.level, function(ret_code)
      if ret_code == 0 then
        local rewards = level_rewards[cfg.level]
        if rewards then
          for _, r in ipairs(rewards) do
            table.insert(success_rewards, r)
          end
        end
      end
      pending = pending - 1
      if pending <= 0 then
        lua_event_module:send_event(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, nil)
        if 0 < #success_rewards then
          self:_show_merged_rewards(success_rewards)
        end
      end
    end)
  end
end

function M:_claim_all_creature_tag_rewards()
  local reward_list = self._creature_tag_reward_list
  if not reward_list then
    return
  end
  local claimable = {}
  for _, rd in ipairs(reward_list) do
    if rd.IsUnlocked and not rd.IsRewardTaken then
      table.insert(claimable, rd)
    end
  end
  if #claimable == 0 then
    return
  end
  local pending = #claimable
  local success_rewards = {}
  for _, rd in ipairs(claimable) do
    CsCodexModuleUtil.TakeCreatureTagNumReward(rd.ConfigId, function(ret_code, rewards)
      if ret_code == 0 and not_null(rewards) and not_null(rewards.RewardItemList) then
        for i = 0, rewards.RewardItemList.Count - 1 do
          local item = rewards.RewardItemList[i]
          table.insert(success_rewards, {
            id = item.ItemConfigId,
            num = item.Count
          })
        end
      end
      pending = pending - 1
      if pending <= 0 then
        lua_event_module:send_event(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, nil)
        if 0 < #success_rewards then
          self:_show_merged_rewards(success_rewards)
        end
      end
    end)
  end
end

function M:_claim_all_tag_num_rewards()
  local reward_list = self._tag_num_reward_list
  if not reward_list then
    return
  end
  local claimable = {}
  for _, rd in ipairs(reward_list) do
    if rd.IsUnlocked and not rd.IsRewardTaken then
      table.insert(claimable, rd)
    end
  end
  if #claimable == 0 then
    return
  end
  local pending = #claimable
  local success_rewards = {}
  for _, rd in ipairs(claimable) do
    CsCodexModuleUtil.TakeTagNumReward(rd.ConfigId, function(ret_code, rewards)
      if ret_code == 0 and not_null(rewards) and not_null(rewards.RewardItemList) then
        for i = 0, rewards.RewardItemList.Count - 1 do
          local item = rewards.RewardItemList[i]
          table.insert(success_rewards, {
            id = item.ItemConfigId,
            num = item.Count
          })
        end
      end
      pending = pending - 1
      if pending <= 0 then
        lua_event_module:send_event(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, nil)
        if 0 < #success_rewards then
          self:_show_merged_rewards(success_rewards)
        end
      end
    end)
  end
end

function M:_show_merged_rewards(success_rewards)
  local merged_map = {}
  local merged_order = {}
  for _, r in ipairs(success_rewards) do
    if merged_map[r.id] then
      merged_map[r.id] = merged_map[r.id] + r.num
    else
      merged_map[r.id] = r.num
      table.insert(merged_order, r.id)
    end
  end
  local items = {}
  for _, id in ipairs(merged_order) do
    table.insert(items, {
      id = id,
      num = merged_map[id]
    })
  end
  common_ui_module:show_reward_dialog(nil, nil, items)
end

function M:_get_next_reward_threshold(current_count)
  if self._creature_tag_reward_list then
    local cc = current_count or 0
    for _, rd in ipairs(self._creature_tag_reward_list) do
      if cc < rd.CreatureNum then
        return rd.CreatureNum
      end
    end
  elseif self._tag_num_reward_list then
    local count = self._unlocked_item_count
    for _, rd in ipairs(self._tag_num_reward_list) do
      if count < rd.Num then
        return rd.Num
      end
    end
  else
    local level_cfgs = self._sub_type_controller:get_unlock_cfgs()
    if level_cfgs then
      local count = current_count or self._unlocked_item_count
      for _, cfg in ipairs(level_cfgs) do
        if count < cfg.num then
          return cfg.num
        end
      end
    end
  end
  return self._item_count
end

return M
