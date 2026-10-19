local M = G.Class("SeasonCodexRewardItem", G.UIPanel)
local base = G.UIPanel
require("UI/Codex/SeasonCodex/CodexSeasonData")
local codex_anim = require("UI/Codex/SeasonCodex/SeasonCodexAnim")
local RewardState = codex_module.season_reward_state

function M:init()
  base.init(self)
  self._cfg = nil
  self._on_claim = nil
  self._item_panel = nil
  self._img_item_icon = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  if not_null(self._obj_item_v2) then
    self._img_item_icon = self._obj_item_v2:GetComponent(typeof(ImageEx))
    if is_null(self._img_item_icon) and not self._item_panel then
      self._item_panel = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item_v2.transform)
    end
  end
  if not_null(self._img_item_icon) then
    self.binder:BindViewCallback(self._img_item_icon.transform, EventTriggerType.PointerClick, pack(self, M._on_item_icon_click))
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_receive) then
    self:bind_callback(self._btn_receive, pack(self, M._on_btn_receive_click))
  end
end

function M:_on_btn_receive_click()
  if not self._cfg then
    return
  end
  if self:_get_reward_state() == RewardState.claimable and self._on_claim then
    self._on_claim(self._cfg)
  end
end

function M:_on_item_icon_click()
  local item_id = self._cfg and self._cfg.item_id or 0
  if 0 < item_id then
    item_module:open_item_info_dialog(item_id)
  end
end

function M:refresh(item_data)
  self._cfg = item_data.cfg
  self._on_claim = item_data.on_claim
  self:_refresh_state()
  self:_refresh_icon()
  self:_refresh_quality()
  self:_refresh_progress_num()
end

function M:refresh_state(cfg)
  if cfg ~= nil then
    self._cfg = cfg
  end
  self:_refresh_state()
end

function M:_get_reward_state()
  return codex_module:get_season_reward_state(self._cfg)
end

function M:_refresh_state()
  local state = self:_get_reward_state()
  if not_null(self._ui_state_group_lock) then
    self._ui_state_group_lock:SetState(state)
  end
  if not_null(self._obj_received) then
    UIUtil.set_active(self._obj_received, state == RewardState.claimed)
  end
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(state == RewardState.claimable and RedPointType.GiftRP or RedPointType.None)
  end
  codex_anim.play(self._animator_helper_card_bg, codex_anim.reward, state == RewardState.claimable and "claimable" or "idle")
end

function M:_refresh_icon()
  if not self._cfg then
    return
  end
  local item_id = self._cfg.item_id or 0
  if self._item_panel and 0 < item_id then
    self._item_panel:set_item_data(item_id, self._cfg.item_count)
    self._item_panel:bind_item_info_btn(item_id, false)
  elseif not_null(self._img_item_icon) and 0 < item_id then
    item_module:set_item_icon(self._img_item_icon, item_id, nil, nil, self:get_load_proxy())
  end
  if not_null(self._txt_count) and self._cfg.item_count then
    local count = self._cfg.item_count
    UIUtil.set_text(self._txt_count, 1 < count and "x" .. count or "")
  end
end

function M:_refresh_quality()
  local rank = 0
  local item_id = self._cfg and self._cfg.item_id or 0
  if 0 < item_id then
    local item_cfg = item_module:get_cfg_by_id(item_id)
    rank = item_cfg and item_cfg.rank or 0
  end
  if not_null(self._ui_state_group_quilty) then
    self._ui_state_group_quilty:SetState(rank)
  end
end

function M:_refresh_progress_num()
  if not_null(self._txt_progress_num) and self._cfg then
    UIUtil.set_text(self._txt_progress_num, self._cfg.count or 0)
  end
end

return M
