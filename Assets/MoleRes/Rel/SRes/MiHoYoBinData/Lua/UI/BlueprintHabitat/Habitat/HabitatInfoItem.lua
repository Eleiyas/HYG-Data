local M = G.Class("HabitatInfoItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._is_config_id_type = false
  self._is_selected = false
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:refresh_as_need_item(title, num, cfg_id, refer_entity)
  if not item_module:has_cfg_by_id(cfg_id) then
    self:set_active(false)
    return
  end
  self:bind_callback(self._btn_config_id, function()
    local bag_num = back_bag_module:get_coin_or_item_num(cfg_id) or 0
    item_module:open_item_info_dialog(cfg_id, bag_num)
  end)
  self._is_config_id_type = true
  self:_refresh_need_common(title, num)
  self:_refresh_item_icon(cfg_id)
  self:_refresh_grid(refer_entity)
end

function M:refresh_as_need_tag(title, num, tag, tag_cb, refer_entity)
  self._is_config_id_type = false
  self:_refresh_need_common(title, num)
  self:_refresh_tag_icon(tag)
  self:_refresh_grid(refer_entity)
  self:bind_callback(self._btn_tag, function()
    if tag_cb ~= nil then
      tag_cb()
    end
  end)
  if not_null(self._state_group_rank) then
    self._state_group_rank:SetState(0)
  end
end

function M:_refresh_need_common(title, num)
  UIUtil.set_text(self._txt_title, title or "")
  if not_null(self._txt_num) then
    UIUtil.set_active(self._txt_num, num ~= nil)
    if num ~= nil then
      UIUtil.set_text(self._txt_num, "x" .. tostring(num))
    end
  end
  self:_refresh_need_btns()
  self:refresh_select_state(false)
end

function M:get_tag_btn()
  return self._btn_tag
end

function M:is_config_id_type()
  return self._is_config_id_type
end

function M:get_top_center_position()
  local corners = CsUIUtil.GetWorldCorners(self.trans)
  local tl, tr = corners[1], corners[2]
  return (tl.x + tr.x) * 0.5, (tl.y + tr.y) * 0.5, (tl.z + tr.z) * 0.5
end

function M:set_slot_id(slot_id)
  self._slot_id = slot_id
end

function M:get_slot_id()
  return self._slot_id
end

function M:_refresh_item_icon(cfg_id)
  UIUtil.set_active(self._img_general, false)
  if is_null(self._img_icon) then
    return
  end
  local cfg = item_module:get_cfg_by_id(cfg_id)
  if cfg == nil or not string.is_valid(cfg.icon) then
    UIUtil.set_active(self._img_icon, false)
    return
  end
  UIUtil.set_active(self._img_icon, true)
  UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
  if not_null(self._state_group_rank) then
    self._state_group_rank:SetState(cfg.rank)
  end
end

function M:_refresh_tag_icon(tag)
  UIUtil.set_active(self._img_icon, false)
  if is_null(self._img_general) then
    return
  end
  UIUtil.set_active(self._img_general, true)
  local tag_id = tag and tag.TagId or 0
  if tag_id <= 0 then
    return
  end
  local icon_path = TagUtil.get_tag_icon(tag_id)
  if string.is_valid(icon_path) then
    UIUtil.set_image(self._img_general, icon_path, self:get_load_proxy())
  end
end

function M:_refresh_need_btns()
  if not_null(self._btn_config_id) then
    UIUtil.set_active(self._btn_config_id, self._is_config_id_type)
  end
  if not_null(self._btn_tag) then
    UIUtil.set_active(self._btn_tag, not self._is_config_id_type)
  end
end

function M:_refresh_grid(refer_entity)
  if is_null(self._txt_grid) then
    return
  end
  if refer_entity == nil or not refer_entity.HasGrid then
    UIUtil.set_active(self._txt_grid, false)
    return
  end
  UIUtil.set_active(self._txt_grid, true)
  local w = string.format("%.1f", refer_entity.GridWidth / 2)
  local h = string.format("%.1f", refer_entity.GridHeight / 2)
  UIUtil.set_text(self._txt_grid, w .. " x " .. h)
  if not_null(self._trans_floor_area) then
    self._trans_floor_area:SetLocalScale(math.min(refer_entity.GridWidth / 2, 3), math.min(refer_entity.GridHeight / 2, 3), 1)
  end
end

function M:refresh_as_condition(habitat_id, requirement_id)
  self._requirement_id = requirement_id or 0
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatRequirementCfg), self._requirement_id)
  if cfg == nil then
    UIUtil.set_text(self._txt_title, "")
    return
  end
  if string.is_valid(cfg.requirementtextid) then
    if self:get_requirement_type() == 1 then
      local half_x, half_y = self:_get_habitat_range_half(habitat_id)
      UIUtil.set_text_by_id(self._txt_title, cfg.requirementtextid, half_x, half_y)
    else
      UIUtil.set_text_by_id(self._txt_title, cfg.requirementtextid)
    end
  else
    UIUtil.set_text(self._txt_title, cfg.requirementdesc or "")
  end
  self:_bind_help_btn(cfg)
end

function M:get_requirement_id()
  return self._requirement_id or 0
end

function M:get_requirement_type()
  if self._requirement_id == 0 then
    return 0
  end
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatRequirementCfg), self._requirement_id)
  if cfg == nil then
    return 0
  end
  return cfg.requirementtype
end

function M:_bind_help_btn(cfg)
  if cfg.jumptoguidemoduleid == 0 or cfg.jumptoguidegroupid == 0 then
    UIUtil.set_active(self._btn_help, false)
  else
    UIUtil.set_active(self._btn_help, true)
  end
  if self._has_bind_help then
    return
  end
  self._has_bind_help = true
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help_click))
end

function M:_get_habitat_range_half(habitat_id)
  local ok, habitat_cfg = CsHabitatModuleUtil.TryGetHabitatCfg(habitat_id)
  local range = ok and habitat_cfg and habitat_cfg.Range
  if range == nil then
    return 0, 0
  end
  return range.x * 0.5, range.y * 0.5
end

function M:_on_btn_help_click()
  if self._requirement_id == 0 then
    return
  end
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatRequirementCfg), self._requirement_id)
  if cfg == nil then
    return
  end
  local module_id = cfg.jumptoguidemoduleid or 0
  local group_id = cfg.jumptoguidegroupid or 0
  if module_id <= 0 or group_id <= 0 then
    return
  end
  tutorial_module:open_tutorial_handbook_page_with_tutorial_id(module_id, group_id)
end

function M:refresh_select_state(is_selected)
  self._is_selected = is_selected and true or false
  UIUtil.set_active(self._trans_select, self._is_selected)
  UIUtil.set_active(self._trans_unselect, not self._is_selected)
end

function M:refresh_finish_state(is_finish)
  self._state_finish:SetState(is_finish and 1 or 0)
end

function M:is_selected()
  return self._is_selected
end

function M:get_btn()
  return self._btn
end

return M
