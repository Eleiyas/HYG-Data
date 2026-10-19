local M = G.Class("ToolSkinItem", G.UIPanel)
local base = G.UIPanel
local worn_and_select_state = {unselect = 0, select = 1}

function M:init()
  base.init(self)
  self._skin_id = 0
  self._index = 0
  self._is_active = false
  self._is_unlocked = false
  self._name_str = ""
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(skin_id, index, active_skin_id, selected_skin_id)
  self._skin_id = skin_id
  self._index = index
  self._is_unlocked = 0 < skin_id and CsToolSkinModuleUtil.IsSkinUnlocked(skin_id)
  self._is_active = skin_id == active_skin_id
  UIUtil.set_active(self._obj_empty, skin_id == 0 or 0 < skin_id and not self._is_unlocked)
  UIUtil.set_active(self._obj_content, 0 < skin_id and self._is_unlocked)
  if not self._is_unlocked then
    if not_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
    return
  end
  local item_cfg = item_module:get_cfg_by_id(skin_id)
  if not is_null(item_cfg) then
    item_module:set_item_big_icon_with_prismatic(self._img_icon, 0, item_cfg, self:get_load_proxy(), self._img_icon_prismatic)
    self._ui_start_group_rank:SetState(item_cfg.rank or 0)
    self._name_str = item_module:get_item_name_by_id(skin_id)
  end
  self:refresh_worn_and_select_state(selected_skin_id)
end

function M:refresh_worn_and_select_state(selected_skin_id)
  local is_select = self.holder:get_select_index() == self._index
  local state = worn_and_select_state.unselect
  if is_select then
    state = worn_and_select_state.select
  else
    state = worn_and_select_state.unselect
  end
  self._ui_start_group_worn:SetState(state)
end

function M:get_skin_id()
  return self._skin_id
end

function M:get_index()
  return self._index
end

function M:get_btn()
  return self._btn
end

function M:is_unlocked()
  return self._is_unlocked
end

function M:is_active()
  return self._is_active
end

function M:get_name_str()
  return self._name_str
end

return M
