local M = G.Class("CurioEmporiumEntranceSeasonBpPanel", G.CurioEmporiumEntrancePanelBase)
local base = G.CurioEmporiumEntrancePanelBase
local reward_item_class = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceSeasonBpRewardItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumBpPanel"
  self._bp_show_cfg = nil
  self._reward_item_pool = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:refresh()
  base.refresh(self)
  local tag_cfg = self._tag_cfg
  local tag_id = tonumber(tag_cfg and tag_cfg.tagid) or 0
  self._bp_show_cfg = ExcelDataUtil.get_value(typeof(BBpShowCfg), tag_id)
  self:_refresh_description()
  self:_refresh_countdown()
  self:_refresh_reward_items()
end

function M:_refresh_description()
  local cfg = self._bp_show_cfg
  if not cfg or is_null(cfg) then
    UIUtil.set_text(self._txt_name, "")
    UIUtil.set_text(self._txt_ad_des, "")
    return
  end
  UIUtil.set_text(self._txt_name, cfg.bptitle)
  UIUtil.set_text(self._txt_ad_des, cfg.bpadvdes)
end

function M:_refresh_countdown()
  local end_timestamp = tonumber(theme_season_module:get_end_timestamp()) or 0
  local now_timestamp = tonumber(TimeUtil.ServerUtcTimeSeconds) or 0
  local remain_seconds = end_timestamp - now_timestamp
  local is_show_time = 0 < end_timestamp and 0 < remain_seconds
  UIUtil.set_active(self._obj_time_group, is_show_time)
  if not is_show_time then
    UIUtil.set_text(self._txt_pass_time, "")
    return
  end
  UIUtil.set_text(self._txt_pass_time, curio_emporium_module:format_remain_time(remain_seconds))
end

function M:_get_reward_item_ids()
  local reward_item_ids = {}
  local cfg = self._bp_show_cfg
  if not cfg or is_null(cfg) then
    return reward_item_ids
  end
  local reward_count = tonumber(cfg.rewardshowLength) or 0
  for index = 0, reward_count - 1 do
    local item_id = tonumber(cfg:rewardshow(index)) or 0
    if 0 < item_id then
      table.insert(reward_item_ids, item_id)
    end
  end
  return reward_item_ids
end

function M:_refresh_reward_items()
  local reward_item_ids = self:_get_reward_item_ids()
  local reward_item_pool = self._reward_item_pool or {}
  self._reward_item_pool = reward_item_pool
  local reward_count = #reward_item_ids
  local max_count = math.max(reward_count, #reward_item_pool)
  if is_null(self._list_item_binder_reward_item) then
    return
  end
  for index = 1, max_count do
    local reward_item = reward_item_pool[index]
    if index <= reward_count then
      if not reward_item then
        local item_obj = self._list_item_binder_reward_item:AddItem(0)
        if not_null(item_obj) then
          reward_item = self:add_panel(reward_item_class, item_obj)
          reward_item_pool[index] = reward_item
        end
      end
      if reward_item then
        reward_item:refresh(reward_item_ids[index], self:get_load_proxy())
        UIUtil.set_active(reward_item.game_obj, true)
      end
    elseif reward_item then
      UIUtil.set_active(reward_item.game_obj, false)
    end
  end
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_go, pack(self, M._on_btn_go_click))
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
end

function M:_on_btn_go_click()
  theme_season_module:open_bp_pay_page()
end

function M:_on_btn_info_click()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local intro_id = season_cfg and season_cfg.introductionid or 0
  if 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

return M
