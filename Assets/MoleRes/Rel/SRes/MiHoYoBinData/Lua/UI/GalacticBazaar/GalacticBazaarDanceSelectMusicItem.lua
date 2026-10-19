local M = G.Class("GalacticBazaarDanceSelectMusicItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self:_bind_toggle()
end

function M:on_enable()
  base.on_enable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:set_data(cfg, on_select_callback)
  if is_null(cfg) then
    return
  end
  self._cfg = cfg
  self._on_select_callback = on_select_callback
  UIUtil.set_text(self._txt_name_unselect, cfg.name or "")
  UIUtil.set_text(self._txt_name_select, cfg.name or "")
  self:_refresh_lock_state()
end

function M:_refresh_lock_state()
  if is_null(self._lock_state) then
    return
  end
  local state = self._cfg and self._cfg.is_unlock == false and 0 or 1
  self._lock_state:SetState(state)
end

function M:_bind_toggle()
  if is_null(self._toggle) then
    return
  end
  self:bind_callback(self._toggle, function(is_on)
    if not is_on then
      return
    end
    if self._on_select_callback then
      self._on_select_callback(self._cfg)
    end
  end)
end

function M:set_selected(selected)
  if is_null(self._toggle) then
    return
  end
  self._toggle.isOn = selected and true or false
end

function M:get_cfg()
  return self._cfg
end

return M
