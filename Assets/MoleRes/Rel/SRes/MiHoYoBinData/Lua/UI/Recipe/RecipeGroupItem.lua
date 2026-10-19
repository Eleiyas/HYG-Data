local M = G.Class("RecipeGroupItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  local extra_data = self:get_extra_data()
  self._on_click = extra_data.on_click
  self._on_tips_click = extra_data.on_tips_click
  self:bind_callback(self._btn, function()
    if self._on_click then
      self._on_click(self)
    end
  end)
  self:bind_callback(self._button_tips, function()
    if self._on_tips_click then
      self._on_tips_click(self)
    end
  end)
end

function M:set_data(group_id, all_recipe_group)
  self.id = group_id
  local group_cfg = recipe_module:get_group_cfg_by_id(group_id)
  local cur_num = #(all_recipe_group[group_id] or {})
  local max_num = #(recipe_module:get_recipe_cfg_ids_by_group_id(group_id) or {})
  local bg_path = group_cfg.lockedpath
  self._red_point_container:ShowRedPoint(RedPointType.None)
  if cur_num == 0 then
    UIUtil.set_text(self._txt_cur_num, "")
    UIUtil.set_text(self._txt_max_num, "")
    UIUtil.set_text(self._txt_title, group_cfg.name)
  else
    if cur_num == max_num then
      UIUtil.set_text(self._txt_cur_num, "")
      UIUtil.set_text(self._txt_max_num, "")
    else
      UIUtil.set_text(self._txt_cur_num, tostring(cur_num))
      UIUtil.set_text(self._txt_max_num, string.format("/%s", max_num))
    end
    if red_point_module:is_recorded_with_id(red_point_module.red_point_type.diy_group_recipe, group_id) then
      self._red_point_container:ShowRedPoint(RedPointType.StrongRP)
    end
    bg_path = group_cfg.lockedpath
    UIUtil.set_text(self._txt_title, group_cfg.name)
  end
  self._state_group:SetState(cur_num == max_num and 1 or 0)
  self._state_title:SetState(cur_num == 0 and 0 or 1)
  UIUtil.set_active(self._button_tips, cur_num < max_num)
  UIUtil.set_text(self._txt_title, group_cfg.name)
  UIUtil.set_image(self._img_bg, bg_path, self.holder:get_load_proxy())
end

function M:delete_red_point_record()
  if red_point_module:is_recorded_with_id(red_point_module.red_point_type.diy_group_recipe, self.id) then
    red_point_module:delete_record_with_id(red_point_module.red_point_type.diy_group_recipe, self.id)
    self._red_point_container:ShowRedPoint(RedPointType.None)
    lua_event_module:send_event(lua_event_module.event_type.diy_group_recipe)
  end
end

function M:set_select(is_select)
  self._button_ex:SetSelect(is_select)
end

function M:reset_state()
  self._button_ex:ResetState()
end

function M:set_btn_state(state)
  self._btn:SetState(state)
end

function M:set_tutorial_key(index)
  local dynamic_tutorial_ui_key = tutorial_module:check_tutorial_dynamic_key(GraphDynamicUIKeyType.HandBookCardGroup, index)
  if dynamic_tutorial_ui_key and dynamic_tutorial_ui_key ~= 0 then
    self._tutorial_marker:ActiveDynamicTutorialKey(dynamic_tutorial_ui_key)
  end
end

return M
