local M = G.Class("FamilyCommentLevelItem", G.UIBase)
local base = G.UIBase
local level_state = {unclaimed = 0, claimed = 1}

function M:on_create()
  base.on_create(self)
end

function M:refresh(level_cfg, current_level, target_hot_num)
  local level = tonumber(level_cfg.socialactivitylevel) or 0
  local level_text = UIUtil.get_text_by_id("Liuyanban_Lv") .. TextMapFormatUtil.FormatInteger(level)
  UIUtil.set_image(self._icon_award, level_cfg.levelicon, self:get_load_proxy())
  UIUtil.set_text(self._txt_lv, level_text)
  UIUtil.set_text(self._txt_hot_num, TextMapFormatUtil.FormatAbbreviation(target_hot_num or 0))
  self._state_group:SetState(current_level >= level and level_state.claimed or level_state.unclaimed)
  UIUtil.set_active(self._trans_hot, level == current_level + 1)
end

return M
