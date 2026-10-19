local M = G.Class("AppearanceSuitItem", G.UIPanel)
local base = G.UIPanel
local worn_state = {not_worn = 0, worn = 1}

function M:init()
  base.init(self)
  self._index = 0
  self._suit_data = nil
  self._name_str = ""
  self._is_worn = false
  self._is_new = false
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh(suit_data, index)
  self._index = index
  self._is_worn = false
  if suit_data == 0 or suit_data == -1 or is_null(suit_data) then
    self._suit_data = nil
    UIUtil.set_active(self._obj_empty, suit_data == 0)
    UIUtil.set_active(self._obj_content, false)
    if not_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
    return
  end
  self._suit_data = suit_data
  UIUtil.set_active(self._obj_empty, false)
  UIUtil.set_active(self._obj_content, true)
  local suit_id = suit_data.suitId
  local item_cfg = item_module:get_cfg_by_id(suit_id)
  if is_null(item_cfg) then
    return
  end
  self._name_str = item_module:get_item_name_by_id(suit_id)
  self._is_worn = CsAppearanceManagerUtil.IsSuitWorn(suit_id)
  self._is_new = not red_point_module:is_recorded_with_id(red_point_module.red_point_type.appearance_cloth_new, suit_id)
  item_module:set_item_big_icon_with_prismatic(self._img_icon, 0, item_cfg, self:get_load_proxy(), self._img_icon_prismatic)
  self._ui_start_group_rank:SetState(item_cfg.rank)
  self:refresh_worn_and_select_state()
  local suit_magic_id = appearance_module:get_suit_magic_id(suit_id)
  UIUtil.set_active(self._img_icon_magic, 0 < suit_magic_id)
end

function M:refresh_worn_and_select_state()
  local state = self._is_worn and worn_state.worn or worn_state.not_worn
  self._ui_start_group_worn:SetState(state)
  self:_refresh_red_point()
end

function M:refresh_worn_state()
  if self._suit_data then
    self._is_worn = CsAppearanceManagerUtil.IsSuitWorn(self._suit_data.suitId)
  end
  self:refresh_worn_and_select_state()
end

function M:is_worn()
  return self._is_worn
end

function M:set_red_point_state()
  if self._is_new then
    local suit_id = self:get_suit_id()
    if 0 < suit_id then
      red_point_module:record_with_id(red_point_module.red_point_type.appearance_cloth_new, suit_id)
    end
    self._is_new = false
  end
  self:_refresh_red_point()
end

function M:_refresh_red_point()
  if self._is_new then
    self._red_point:ShowRedPoint(red_point_module.point_style_type.new_rp)
  else
    self._red_point:ShowRedPoint(red_point_module.point_style_type.none)
  end
end

function M:get_index()
  return self._index
end

function M:get_btn()
  return self._btn
end

function M:get_name_str()
  return self._name_str
end

function M:get_suit_data()
  return self._suit_data
end

function M:get_suit_id()
  if self._suit_data then
    return self._suit_data.suitId
  end
  return 0
end

function M:is_complete()
  if self._suit_data then
    return self._suit_data.isComplete
  end
  return false
end

function M:get_trans()
  return self.trans
end

function M:refresh_tutorial_key(index)
  if is_null(self._tutorial_marker) then
    return false
  end
  local dynamic_tutorial_ui_key = tutorial_module:check_tutorial_dynamic_key(GraphDynamicUIKeyType.UnlockCloth, index)
  if dynamic_tutorial_ui_key and dynamic_tutorial_ui_key ~= 0 then
    self._tutorial_marker:ActiveDynamicTutorialKey(dynamic_tutorial_ui_key)
    return true
  end
  return false
end

return M
