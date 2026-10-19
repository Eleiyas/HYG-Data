local M = G.Class("GeLianMarketReturnRankEntryPanel", G.UIPanel)
local base = G.UIPanel
local color_util = gelian_market_module.color_util

function M:init()
  base.init(self)
  self._row = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_avatar, pack(self, M._on_btn_avatar))
end

function M:render(row, in_list)
  self._row = row
  self:hide_action_btns()
  self:set_active(row ~= nil)
  if row == nil then
    return
  end
  self._state_group_list:SetState(in_list and 0 or 1)
  local rank_state = not (not row.is_profit_hidden or row.is_self) and 2 or row.is_rank_eligible and 0 or 1
  self._state_group_lock:SetState(rank_state)
  self._state_group_state:SetState(row.is_online and 1 or 0)
  UIUtil.set_text(self._txt_rank, row.is_rank_eligible and row.rank or "-")
  UIUtil.set_text(self._txt_name, row.nickname or "")
  UIUtil.set_text(self._txt_signature, row.title or "")
  if row.is_profit_hidden and not row.is_self then
    UIUtil.set_text(self._txt_return_ratio, "--", self:_calc_return_ratio_color_key(0, in_list))
  else
    local basis_points = row.profit_rate_basis_points or 0
    UIUtil.set_text(self._txt_return_ratio, TextMapFormatUtil.FormatPercent(basis_points / 10000, 2), self:_calc_return_ratio_color_key(basis_points, in_list))
  end
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), row.avatar_id or 1)
  if head_cfg ~= nil then
    UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
  end
end

function M:_calc_return_ratio_color_key(basis_points, in_list)
  return color_util.get_profit_color_key(basis_points or 0, not in_list)
end

function M:hide_action_btns()
end

function M:_on_btn_avatar()
  local row = self._row
  if row == nil or row.is_self then
    return
  end
  UIManagerInstance:open("UI/GeLianMarket/FoodMarketAvatarBtnDialog", {
    uid = row.uid,
    show_chat = true,
    align_target = self._btn_avatar.transform,
    offset = Vector2(0, 0)
  })
end

return M
