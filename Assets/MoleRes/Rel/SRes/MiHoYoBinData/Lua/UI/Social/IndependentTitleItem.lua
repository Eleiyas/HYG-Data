local M = G.Class("IndependentTitleItem", G.UIPanel)
local base = G.UIPanel
local title_container_cls = "UI/Social/PlayerTitleContainer"
local lock_state = {locked = 0, unlocked = 1}
local select_state = {unselected = 0, selected = 1}
local equipped_state = {unequipped = 0, equipped = 1}

function M:init()
  base.init(self)
  self._title_cfg = nil
  self._on_toggle_callback = nil
  self._toggle = nil
  self._title_item = nil
  self._is_selected = false
  self._ui_state_group_select = nil
  self._ui_state_group_is_lock = nil
  self._ui_state_group_is_select = nil
  self._red_point = nil
  self._trans_star_friend_title_parent = nil
end

function M:on_create()
  base.on_create(self)
  self._toggle = self.trans.gameObject:GetComponent(typeof(ToggleEx))
  self._ui_state_group_select = self.trans.gameObject:GetComponent(typeof(UIStateChangeGroup))
  self:bind_callback(self._toggle, pack(self, M._on_toggle))
  local toggle_group = self._toggle.group
  if not_null(toggle_group) then
    toggle_group.allowSwitchOff = true
  end
  self._title_item = self:add_panel(title_container_cls, self._trans_star_friend_title_parent)
end

function M:on_destroy()
  self._title_cfg = nil
  self._on_toggle_callback = nil
  self._toggle = nil
  self._title_item = nil
  self._ui_state_group_select = nil
  base.on_destroy(self)
end

function M:refresh(title_cfg, on_toggle_callback)
  self._title_cfg = title_cfg
  self._on_toggle_callback = on_toggle_callback
  self._is_selected = false
  self:refresh_title()
  local is_unlocked = social_module.unlock_title_ids[title_cfg.titleid] == true
  self._ui_state_group_is_lock:SetState(is_unlocked and lock_state.unlocked or lock_state.locked)
  self._toggle.interactable = is_unlocked
  self:_refresh_red_point()
  self:_apply_selected_visual()
end

function M:refresh_title()
  if not self._title_cfg then
    return
  end
  local title_id = self._title_cfg.titleid
  local title = social_module:resolve_title_text(self._title_cfg.playertitlename, title_id)
  self._title_item:refresh({title_id}, title)
end

function M:set_selected(is_selected, notify)
  self._is_selected = is_selected == true
  if not self._toggle then
    self:_apply_selected_visual()
    return
  end
  if notify == false then
    self._toggle.isOnValue = self._is_selected
  elseif self._toggle.isOn ~= self._is_selected then
    self._toggle.isOn = self._is_selected
  end
  self:_apply_selected_visual()
end

function M:_apply_selected_visual()
  if self._ui_state_group_select then
    self._ui_state_group_select:SetState(self._is_selected and select_state.selected or select_state.unselected)
  end
  if self._toggle and self._toggle.graphicSelect then
    self._toggle.graphicSelect.gameObject:SetActive(self._is_selected)
  end
end

function M:set_equipped(is_equipped)
  if is_null(self._ui_state_group_is_select) then
    return
  end
  self._ui_state_group_is_select:SetState(is_equipped and equipped_state.equipped or equipped_state.unequipped)
end

function M:get_title_cfg()
  return self._title_cfg
end

function M:clear_red_point()
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_refresh_red_point()
  local red_point_type = red_point_module:is_recorded_with_id(red_point_module.red_point_type.player_title, self._title_cfg.titleid) and RedPointType.StrongRP or RedPointType.None
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(red_point_type)
  end
end

function M:_on_toggle(is_on)
  if self._on_toggle_callback then
    self._on_toggle_callback(self, is_on)
  end
end

return M
