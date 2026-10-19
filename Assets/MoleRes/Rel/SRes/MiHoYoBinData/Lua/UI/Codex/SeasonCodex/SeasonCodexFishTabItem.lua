local M = G.Class("SeasonCodexFishTabItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._fish_sub = nil
  self._style_state = nil
  self._on_selected = nil
end

function M:on_create()
  base.on_create(self)
  if is_null(self._red_point) and not_null(self.trans) then
    self._red_point = self.trans:GetComponentInChildren(typeof(MonoRedPointContainer), true)
  end
  if not_null(self._tog_tab) then
    self:bind_callback(self._tog_tab, pack(self, M._on_toggle_changed))
  end
end

function M:setup(fish_sub, title, style_state, on_selected)
  self._fish_sub = fish_sub
  self._style_state = style_state
  self._on_selected = on_selected
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, title or "")
  end
  if not_null(self._ui_state_group_style) and style_state ~= nil then
    self._ui_state_group_style:SetState(style_state)
  end
end

function M:refresh_num(unlocked, total)
  if is_null(self._txt_num) then
    return
  end
  UIUtil.set_text(self._txt_num, (unlocked or 0) .. "/" .. (total or 0))
end

function M:refresh_red_point(has_new)
  if is_null(self._red_point) then
    return
  end
  UIUtil.set_active(self._red_point, true)
  self._red_point:ShowRedPoint(has_new and RedPointType.NewRp or RedPointType.None)
end

function M:set_selected(is_on)
  if not_null(self._tog_tab) then
    self._tog_tab.isOn = is_on
  end
end

function M:_on_toggle_changed(is_on)
  if is_on and self._on_selected and self._fish_sub ~= nil then
    self._on_selected(self._fish_sub)
  end
end

return M
