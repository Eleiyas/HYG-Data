local M = G.Class("AccompanyingBtnTips", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Accompanying/AccompanyingBtnTips"
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_open_detail) then
    self:bind_callback(self._btn_open_detail, pack(self, M._on_btn_open_detail_click))
  end
end

function M:refresh_view()
  if not_null(self._text_state) then
    local role = CsGameplayUtilitiesReactionUtil.GetMutualBenefitRole()
    UIUtil.set_active(self._img_icon_leader, role ~= 0 and role == 1)
    UIUtil.set_active(self._img_icon_follow, role ~= 0 and role ~= 1)
    if role == 0 then
      UIUtil.set_text(self._text_state, "")
      return
    end
    if role == 1 then
      UIUtil.set_text_by_id(self._text_state, "FRIEND_COMPANION_STATUS_LEADING")
    else
      UIUtil.set_text_by_id(self._text_state, "FRIEND_COMPANION_STATUS_FOLLOWING")
    end
  end
end

function M:_on_btn_open_detail_click()
  accompanying_module:open_dialog()
end

return M
