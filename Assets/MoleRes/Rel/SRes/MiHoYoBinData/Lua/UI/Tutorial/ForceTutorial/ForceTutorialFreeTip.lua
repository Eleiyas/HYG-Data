local M = G.Class("ForceTutorialFreeTip", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
end

function M:set_text(text)
  local filtered_text = UIUtil.layout_text_filter(text)
  UIUtil.set_text_with_dynamic_sprite(self._text, filtered_text)
end

function M:refresh_tip(tip_data)
  if tip_data then
    if tip_data.showHeadIcon then
      self._ui_state_tip:SetState(0)
      self._trans_txt_bg.offsetMin = Vector2(100, self._trans_txt_bg.offsetMin.y)
      self._layout_tip.padding.left = 120
      UIUtil.set_image(self._img_npc_profile, tip_data.icon, self:get_load_proxy())
    else
      self._ui_state_tip:SetState(1)
      self._trans_txt_bg.offsetMin = Vector2(0, self._trans_txt_bg.offsetMin.y)
      self._layout_tip.padding.left = 20
    end
    self._ui_state_dir:SetState(tip_data.dir)
    if tip_data.framePosOffset and (tip_data.framePosOffset.x ~= 0 or tip_data.framePosOffset.y ~= 0) then
      local parent_size = self._trans_tip.parent.rect
      local cur_pos = self._trans_tip.anchoredPosition
      local offset_x = parent_size.width * tip_data.framePosOffset.x
      local offset_y = parent_size.height * tip_data.framePosOffset.y
      self._trans_tip.anchoredPosition = Vector2(cur_pos.x + offset_x, cur_pos.y + offset_y)
    end
    if tip_data.showSubTip and tip_data.subTipData then
      UIUtil.set_active(self._sub_tip, true)
      UIUtil.set_text(self._sub_tip, tip_data.subTipData.tip)
      if self._sub_tip_orientation then
        self._sub_tip_orientation:SetOrientationType(tip_data.subTipData.orientation)
      end
    else
      UIUtil.set_active(self._sub_tip, false)
    end
  else
    UIUtil.set_active(self._sub_tip, false)
  end
end

return M
