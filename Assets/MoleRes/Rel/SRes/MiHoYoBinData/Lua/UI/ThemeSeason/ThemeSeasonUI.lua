theme_season_module = theme_season_module or {}
local MAIN_PAGE_CLS = "UI/ThemeSeason/ThemeSeasonMainPage"
local GIFT_CONFIRM_TEXT_ID = "ThemeSeason_UI_047"
local GIFT_DIALOG_TITLE_TEXT_ID = "ThemeSeason_UI_050"
local GIFT_CONFIRM_TITLE_TEXT_ID = "ThemeSeason_UI_065"

function theme_season_module:open_theme_season_main_page()
  local guid = UIManagerInstance:open(MAIN_PAGE_CLS)
  self._main_page_guid = guid
end

function theme_season_module:_ensure_season_active()
  if not self:is_season_active() then
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_010")
    return false
  end
  return true
end

function theme_season_module:on_coin_item_add_click(coin_id)
  if not coin_id or coin_id <= 0 then
    return
  end
  common_ui_module:show_coin_lack_dialog(coin_id)
end

function theme_season_module:try_block_bp_shop_with_tip()
  if not CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseBpShop) then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

function theme_season_module:open_bp_pay_page()
  if self:try_block_bp_shop_with_tip() then
    return
  end
  if not self:_ensure_season_active() then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonBPPayPage")
end

function theme_season_module:open_plot_page()
  if not self:_ensure_season_active() then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonPlotPage")
end

function theme_season_module:open_daily_page()
  if not self:_ensure_season_active() then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonDailyPage")
end

function theme_season_module:open_npc_impression_hall_page()
  if not self:_ensure_season_active() then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonNpcImpressionHallPage")
end

function theme_season_module:open_season_codex_page()
  local season_id = self:get_cur_season_id()
  if season_id == 0 then
    return false
  end
  UIManagerInstance:open("UI/Codex/SeasonCodex/SeasonCodexMainPage", {season_id = season_id})
  return true
end

function theme_season_module:open_graduation_dialog()
  if not self:_ensure_season_active() then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonGraduationDialog")
end

function theme_season_module:open_bp_gift_dialog(gift_item_id)
  if not self:_ensure_season_active() then
    return false
  end
  if gift_item_id == nil or gift_item_id <= 0 then
    return false
  end
  common_ui_module:open_gift_friend_select_dialog({
    title_key = GIFT_DIALOG_TITLE_TEXT_ID,
    gift_item_id = gift_item_id,
    gift_item_num = theme_season_module.GIFT_ITEM_NUM,
    confirm_title_key = GIFT_CONFIRM_TITLE_TEXT_ID,
    build_confirm_text = function(target)
      return UIUtil.get_text_by_id(GIFT_CONFIRM_TEXT_ID, item_module:get_item_name_by_id(gift_item_id), target and target.name or "", self:get_gift_bp_unlock_name(gift_item_id))
    end,
    build_targets = function()
      return self:build_gift_target_list()
    end,
    validate = function()
      if not self:is_season_active() then
        UIUtil.show_tips_by_text_id("ThemeSeason_UI_007")
        return false
      end
      if self:is_season_closing(self.CONST_TYPE.FORBID_GIFT_BP_MINUTES) then
        local time_str = UIUtil.format_left_time(self:get_remaining_seconds())
        UIUtil.show_tips_by_text_id("ThemeSeason_UI_086", time_str)
        return false
      end
      return true
    end,
    on_info = function()
      common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.bp_gift)
    end,
    on_sent = function()
      self:open_bp_gift_giving_page()
    end
  })
  return true
end

function theme_season_module:open_bp_gift_giving_page()
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonBpGiftGivingPage")
end

function theme_season_module:open_bp_gift_receive_dialog(ctx)
  if ctx == nil or ctx.gift_id == nil or ctx.gift_id <= 0 then
    return
  end
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonBpGiftReceiveDialog", ctx)
end

function theme_season_module:open_bp_purchase_success_dialog(product_id)
  if product_id == nil or product_id <= 0 then
    return
  end
  local info = self:get_bp_purchase_info(product_id)
  if info.coupon_only and 0 < info.gift_item_id then
    common_ui_module:show_reward_dialog(nil, nil, {
      {
        id = info.gift_item_id,
        num = info.gift_item_count
      }
    })
    return
  end
  local page = (info.is_double or info.is_luxury) and "UI/ThemeSeason/ThemeSeasonBpRewardPage" or "UI/ThemeSeason/ThemeSeasonBpRewardPage2"
  UIManagerInstance:open(page, {info = info})
end

function theme_season_module:open_chapter_detail_page(chapters, selected_index)
  UIManagerInstance:open("UI/ThemeSeason/ThemeSeasonChapterDetailPage", {chapters = chapters, selected_index = selected_index})
end

function theme_season_module:open_current_chapter_detail()
  if not self:_ensure_season_active() then
    return
  end
  local acts = self:build_story_acts_data()
  if acts == nil or #acts == 0 then
    self:open_plot_page()
    return
  end
  local target_chapters, target_index = nil, 0
  local fallback_chapters, fallback_index = nil, 0
  for _, act in ipairs(acts) do
    local chapters = act.chapters or {}
    for i = 1, #chapters do
      local cfg = self:get_theme_season_story_task_cfg_by_id(chapters[i].id)
      if cfg then
        if self:is_chapter_in_progress(cfg) then
          target_chapters, target_index = chapters, i
          break
        elseif cfg.endtask and 0 < cfg.endtask and task_module:task_is_finish(cfg.endtask) then
          fallback_chapters, fallback_index = chapters, i
        end
      end
    end
    if 0 < target_index then
      break
    end
  end
  if target_index <= 0 then
    target_chapters = fallback_chapters or acts[1].chapters
    target_index = 0 < fallback_index and fallback_index or 1
  end
  if target_chapters and 0 < #target_chapters then
    self:open_chapter_detail_page(target_chapters, target_index)
  else
    self:open_plot_page()
  end
end

function theme_season_module:goto_season_task_in_memo(story_task_id)
  local task_id = self:get_season_memo_task_id(story_task_id)
  self:close_all_season_pages()
  if 0 < task_id then
    memo_module:open_memo_page(false, memo_module.tab_type.task, self:_get_season_memo_category_id(), task_id)
  else
    memo_module:open_memo_page(false)
  end
end

function theme_season_module:format_unlock_remaining_time(remain_seconds)
  return UIUtil.get_text_by_id("ThemeSeason_UI_036", UIUtil.format_left_time(remain_seconds))
end

function theme_season_module:format_season_remaining_time(remain_seconds)
  return UIUtil.get_text_by_id("ThemeSeason_UI_014", UIUtil.format_left_time(remain_seconds))
end

theme_season_module._season_end_popup_pending = false
local SEASON_PAGE_CLASSES = {
  "UI/ThemeSeason/ThemeSeasonBPPayPage",
  "UI/ThemeSeason/ThemeSeasonPlotPage",
  "UI/ThemeSeason/ThemeSeasonDailyPage",
  "UI/ThemeSeason/ThemeSeasonChapterDetailPage",
  "UI/ThemeSeason/ThemeSeasonNpcImpressionHallPage",
  "UI/ThemeSeason/ThemeSeasonGraduationDialog"
}

function theme_season_module:_get_opened_main_page()
  if self._main_page_guid == nil then
    return nil
  end
  return UIManagerInstance:get_windows_by_guid(self._main_page_guid)
end

function theme_season_module:_has_showing_season_page()
  local main_page = self:_get_opened_main_page()
  if main_page and main_page.is_active then
    return true
  end
  for _, class_path in ipairs(SEASON_PAGE_CLASSES) do
    local page = UIManagerInstance:get_window_by_class(class_path)
    if page and page.is_active then
      return true
    end
  end
  return false
end

function theme_season_module:close_all_season_pages()
  if self._main_page_guid then
    UIManagerInstance:close(self._main_page_guid)
    self._main_page_guid = nil
  end
  for _, class_path in ipairs(SEASON_PAGE_CLASSES) do
    local page = UIManagerInstance:get_window_by_class(class_path)
    if page then
      page:close_self()
    end
  end
end

function theme_season_module:mark_season_end_popup_pending()
  self._season_end_popup_pending = true
  self:try_show_season_expired_popup()
end

function theme_season_module:clear_season_end_popup_pending()
  self._season_end_popup_pending = false
end

function theme_season_module:try_show_season_expired_popup()
  if not self._season_end_popup_pending then
    return false
  end
  if not self:_has_showing_season_page() then
    return false
  end
  self._season_end_popup_pending = false
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_texts(UIUtil.get_text_by_id("ThemeSeason_UI_011"), UIUtil.get_text_by_id("Common_Yes"), nil, nil)
  popup:set_callbacks(function()
    self:close_all_season_pages()
  end)
  popup:show()
  return true
end

function theme_season_module:try_show_memo_expired_task_dialog(on_confirm)
  if not self:has_pending_expired_dialog() then
    return false
  end
  local expired_ids = self:get_expired_season_task_ids()
  if expired_ids == nil or #expired_ids <= 0 then
    return false
  end
  local task_names = {}
  for _, task_id in ipairs(expired_ids) do
    local step_cfg = task_module:get_task_step_cfg_by_id(task_id)
    if step_cfg and step_cfg.isshowintaskwindow then
      if step_cfg.name_l10n then
        table.insert(task_names, step_cfg.name_l10n:ToString())
      else
        table.insert(task_names, tostring(task_id))
      end
    end
  end
  if #task_names <= 0 then
    self:on_expired_dialog_shown()
    return false
  end
  UIManagerInstance:open("UI/ThemeSeason/BattlePassSeasonEndDialog", {
    task_names = task_names,
    on_confirm = function()
      self:on_expired_dialog_shown()
      if on_confirm then
        on_confirm()
      end
    end
  })
  return true
end

function theme_season_module:report_page_reach(page_id)
  if page_id == nil or page_id <= 0 then
    return
  end
  CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.theme_season_page_reach, "theme_season_page_reach", {page_id = page_id})
end

return theme_season_module
