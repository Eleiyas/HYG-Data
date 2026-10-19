local M = G.Class("PlayerIntimacyStarSelectItem", G.UIPanel)
local base = G.UIPanel
local ITEM_STATE = {
  NONE = 0,
  SELECTED = 1,
  UNSELECTED = 2
}

function M:on_create()
  base.on_create(self)
  self._cur_state = ITEM_STATE.NONE
  self:_bind_toggle()
end

function M:on_enable()
  base.on_enable(self)
end

function M:set_data(cfg, on_select_callback, load_proxy)
  if is_null(cfg) then
    return
  end
  self._cfg = cfg
  self._on_select_callback = on_select_callback
  self._load_proxy = load_proxy
  if not_null(self._txt_title) then
    UIUtil.set_text(self._txt_title, cfg.impressionname)
  end
  if not_null(self._img_icon) and string.is_valid(cfg.impressionicon) then
    UIUtil.set_image(self._img_icon, cfg.impressionicon, load_proxy)
  end
end

function M:_bind_toggle()
  if is_null(self._toggle) then
    return
  end
  self:bind_callback(self._toggle, function(is_on)
    if self._on_select_callback then
      self._on_select_callback(self._cfg, is_on)
    end
  end)
end

function M:refresh_state(selected_id)
  self:_apply_state(self:_calc_state(selected_id))
end

function M:sync_toggle_on(selected_id)
  if is_null(self._toggle) then
    return
  end
  self._toggle:SetIsOnWithoutNotify(self:_calc_state(selected_id) == ITEM_STATE.SELECTED)
end

function M:set_interactable(interactable)
  if is_null(self._toggle) then
    return
  end
  self._toggle.interactable = interactable and true or false
end

function M:get_state()
  return self._cur_state
end

function M:_calc_state(selected_id)
  if selected_id == nil then
    return ITEM_STATE.NONE
  end
  if self._cfg ~= nil and self._cfg.id == selected_id then
    return ITEM_STATE.SELECTED
  end
  return ITEM_STATE.UNSELECTED
end

function M:_apply_state(state)
  self._cur_state = state
  if not_null(self._state) then
    self._state:SetState(state)
  end
end

function M:get_cfg()
  return self._cfg
end

return M
