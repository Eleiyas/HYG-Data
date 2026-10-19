local M = G.Class("AccompanyingDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Accompanying/AccompanyingDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_refresh_view()
  local leader_bonus = ExcelDataUtil.get_value(typeof(BPlayerCfg), AccompanyingConst.play_cfg_leader).paramstr
  local follower_bonus = ExcelDataUtil.get_value(typeof(BPlayerCfg), AccompanyingConst.play_cfg_follower).paramstr
  leader_bonus = tonumber(leader_bonus) or 0
  follower_bonus = tonumber(follower_bonus) or 0
  leader_bonus = leader_bonus * 100
  follower_bonus = follower_bonus * 100
  UIUtil.set_text_by_id(self._text_lead, "FRIEND_COMPANION_BOOST_PERCENT", leader_bonus)
  UIUtil.set_text_by_id(self._text_follow, "FRIEND_COMPANION_BOOST_PERCENT", follower_bonus)
end

function M:_on_btn_confirm_click()
  self:close_self()
  CsGameplayUtilitiesReactionUtil.EndMutualBenefitTrain()
end

return M
