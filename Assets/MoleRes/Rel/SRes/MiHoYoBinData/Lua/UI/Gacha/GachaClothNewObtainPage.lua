local M = G.Class("GachaClothNewObtainPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.cloth_new_obtain
  self.config.type = EUIType.Page
  self._show_info = nil
  self._cur_item_index = 0
  self._cur_item_id = 0
  self._pre_mode_auto_rotate = false
  self._cur_progress_info = nil
  self._show_skip = false
  self._dt_progress = nil
  self._refresh_seq = 0
  self._is_enabled = false
  self._is_refresh = false
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_mask) then
    self:bind_callback(self._btn_mask, pack(self, M._on_click_mask))
  end
  if not_null(self._btn_skip) then
    self:bind_callback(self._btn_skip, pack(self, M._on_click_skip))
  end
  if not_null(self._btn_info_dark) then
    self:bind_callback(self._btn_info_dark, pack(self, M._on_click_item_info))
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_skip)
end

function M:on_enable()
  base.on_enable(self)
  self._is_enabled = true
  self._preview_token = nil
  self._pre_mode_auto_rotate = ModelPreviewManagerIns.mode_auto_rotate
  self:_refresh_item_data()
end

function M:on_disable()
  base.on_disable(self)
  ModelPreviewManagerIns.mode_auto_rotate = self._pre_mode_auto_rotate
  ModelPreviewManagerIns:hide(self._preview_token)
  ModelPreviewManagerIns:recycle_anim_effect()
  self:_kill_progress_tween()
  self._refresh_seq = self._refresh_seq + 1
  self.binder:StopAnimation()
  self._is_enabled = false
  self._is_refresh = false
end

function M:refresh()
  self._is_refresh = true
  self._show_info = self:get_extra_data()
  self._cur_item_index = 0
  self._show_skip = self._show_info and not self._show_info.is_exchange or false
  self:_init_progress_info()
  self:_refresh_item_data()
end

function M:_init_progress_info()
  if self._show_info == nil or self._show_info.gacha_id == nil then
    return
  end
  local gacha_id = self._show_info.gacha_id
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local drawn_map, exchanged_map = gacha_module:build_owned_data_snapshot(gacha_id)
  local suit_owned, suit_total = gacha_module:get_collect_progress(gacha_id, GachaConst.shop_category.suit, drawn_map, exchanged_map)
  local all_owned, all_total = gacha_module:get_collect_progress(gacha_id, -1, drawn_map, exchanged_map)
  if self._show_info.item_ids then
    for i = 1, #self._show_info.item_ids do
      local item_id = self._show_info.item_ids[i]
      local exchange_cfg = gacha_module:get_exchange_shop_cfg_by_item_id(activity_cfg.gachapoolid, item_id)
      local is_suit = exchange_cfg ~= nil and exchange_cfg.shoptag == GachaConst.shop_category.suit or false
      if is_suit then
        suit_owned = suit_owned - 1
      end
      all_owned = all_owned - 1
    end
  end
  self._cur_progress_info = {
    suit_owned = suit_owned,
    suit_total = suit_total,
    all_owned = all_owned,
    all_total = all_total
  }
end

function M:_get_cur_progress_info(is_suit)
  if self._cur_progress_info == nil then
    return 0, 0
  end
  local owned = 0
  self._cur_progress_info.all_owned = self._cur_progress_info.all_owned + 1
  if is_suit then
    self._cur_progress_info.suit_owned = self._cur_progress_info.suit_owned + 1
    owned = self._cur_progress_info.suit_owned
  else
    owned = self._cur_progress_info.all_owned
  end
  local total = is_suit and self._cur_progress_info.suit_total or self._cur_progress_info.all_total
  return owned, total
end

function M:_refresh_item_data()
  if not self._is_enabled or not self._is_refresh then
    return
  end
  if self._show_info == nil or self._show_info.item_ids == nil or self._cur_progress_info == nil then
    self:_show_end_logic()
    return
  end
  self._cur_item_index = self._cur_item_index + 1
  local item_id = self._show_info.item_ids[self._cur_item_index]
  if item_id == nil or item_id <= 0 then
    self:_show_end_logic()
    return
  end
  local gacha_id = self._show_info.gacha_id
  self._cur_item_id = self:_resolve_model_id(gacha_id, item_id)
  self:_refresh_item_name(item_id)
  self:_refresh_model_preview(self._cur_item_id)
  local owned, total = self:_refresh_pool_progress_info(gacha_id, item_id)
  self:_kill_progress_tween()
  self:_set_buttons_active(false)
  self._refresh_seq = self._refresh_seq + 1
  local seq = self._refresh_seq
  self.binder:StopAnimation()
  self.binder:PlayAnimation("anim_gachashowclothT00page_in", function()
    if self._refresh_seq ~= seq then
      return
    end
    self:_set_buttons_active(true)
    self:_refresh_pool_progress(owned, total)
    gacha_module:notify_codex_unlock_hud(self._cur_item_id)
  end)
end

function M:_set_buttons_active(active)
  UIUtil.set_active(self._btn_mask, active)
  UIUtil.set_active(self._btn_skip, active and self._show_skip or false)
end

function M:_resolve_model_id(gacha_id, item_id)
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return item_id
  end
  local exchange_cfg = gacha_module:get_exchange_shop_cfg_by_item_id(activity_cfg.gachapoolid, item_id)
  if exchange_cfg and exchange_cfg.modelid and exchange_cfg.modelid > 0 then
    return exchange_cfg.modelid
  end
  return item_id
end

function M:_kill_progress_tween()
  if self._dt_progress ~= nil then
    self._dt_progress:Kill()
    self._dt_progress = nil
  end
end

function M:_refresh_pool_progress_info(gacha_id, item_id)
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local exchange_cfg = gacha_module:get_exchange_shop_cfg_by_item_id(activity_cfg.gachapoolid, item_id)
  local is_suit = exchange_cfg ~= nil and exchange_cfg.shoptag == GachaConst.shop_category.suit or false
  local owned, total = self:_get_cur_progress_info(is_suit)
  self._state_group:SetState(is_suit and 1 or 0)
  local suit_name = activity_cfg.name or ""
  if not is_suit then
    suit_name = UIUtil.get_text_by_id("Gacha_Common_AllCollection_Title") or ""
  elseif not_null(self._img_icon_suit) and exchange_cfg.suitid and 0 < exchange_cfg.suitid then
    item_module:set_item_big_icon(self._img_icon_suit, exchange_cfg.suitid, nil, self:get_load_proxy())
    UIUtil.set_active(self._img_icon_suit, true)
  else
    UIUtil.set_active(self._img_icon_suit, false)
  end
  UIUtil.set_text(self._txt_suits_name, suit_name)
  UIUtil.set_text(self._txt_progress, tostring(owned) .. "/" .. tostring(total))
  if not_null(self._slider_progress) then
    local from = 0 < total and (owned - 1) / total or 0
    self:_kill_progress_tween()
    self._slider_progress.value = from
  end
  return owned, total
end

function M:_refresh_pool_progress(owned, total)
  if owned == nil or total == nil then
    return
  end
  if total <= 0 then
    return
  end
  if not_null(self._slider_progress) then
    local target = owned / total
    self:_kill_progress_tween()
    self._dt_progress = self._slider_progress:DOValue(target, 0.5):SetEase(Ease.InOutQuad)
  end
end

function M:_refresh_item_name(item_id)
  if item_id == nil or item_id <= 0 then
    return
  end
  local item_name = item_module:get_item_name_by_id(item_id) or ""
  UIUtil.set_text(self._txt_item_name, item_name)
end

function M:_refresh_model_preview(item_id)
  ModelPreviewManagerIns:hide()
  local target = item_module:is_clothing(item_id) and self._trans_3d_cloth_model or self._trans_3d_model
  self._preview_token = ModelPreviewManagerIns:show_item_by_id(target, item_id, pack(self, self._on_model_loaded), nil, nil, nil, false)
end

function M:_on_model_loaded(go)
  if is_null(go) then
    Logger.Log("[GachaClothNewObtainPage] on_model_loaded failed")
    return
  end
  if self._cur_item_id == nil or self._cur_item_id <= 0 then
    return
  end
  local rank = item_module:get_item_quality_by_id(self._cur_item_id) or 0
  local effect_path = GachaConst.new_obtain_effect_by_rank[rank]
  ModelPreviewManagerIns:play_animation_and_effect(GachaConst.new_obtain_anim, effect_path)
end

function M:_show_end_logic()
  if self._show_info and self._show_info.is_exchange and self._show_info.is_all_collected then
    gacha_module:open_all_collect_banner(self._show_info.gacha_id)
    self.holder:close_self()
  elseif self._show_info and not self._show_info.is_exchange then
    self.holder:show_result_panel()
  else
    self.holder:close_self()
  end
end

function M:_on_click_mask()
  self:_refresh_item_data()
end

function M:_on_click_skip()
  self:_show_end_logic()
end

function M:_on_click_item_info()
  if self._show_info == nil or self._show_info.item_ids == nil then
    return
  end
  local item_id = self._show_info.item_ids[self._cur_item_index]
  if item_id == nil or item_id <= 0 then
    return
  end
  item_module:open_item_info_dialog(item_id)
end

return M
