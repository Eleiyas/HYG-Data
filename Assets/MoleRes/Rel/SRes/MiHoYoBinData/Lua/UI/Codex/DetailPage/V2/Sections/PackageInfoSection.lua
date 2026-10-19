local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("PackageInfoSection", base_path)
local base = G.DetailSectionBase

function M:on_create()
  base.on_create(self)
  self._package_id = 0
  self:bind_callback(self._btn_package_goto, pack(self, M._on_btn_package))
end

function M:should_show(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return false
  end
  local package_id = self:_get_package_id(item_data)
  return package_id ~= 0 and not is_null(codex_module:get_data_by_id(package_id))
end

function M:refresh(item_data)
  self._package_id = self:_get_package_id(item_data)
  local pkg_data = codex_module:get_data_by_id(self._package_id)
  if not pkg_data then
    UIUtil.set_text(self._txt_package_name, codex_module.default_lock_info)
    return
  end
  UIUtil.set_text(self._txt_package_name, pkg_data.IdCfg.name)
  local is_cloth = item_data.Type == CodexDataType.Cloth
  if not_null(self._ui_state_group_package_type) then
    self._ui_state_group_package_type:SetState(is_cloth and 1 or 0)
  end
  local rank = not_null(pkg_data.ItemCfg) and pkg_data.ItemCfg.rank or 0
  if not_null(self._ui_state_group_quality) then
    self._ui_state_group_quality:SetState(rank)
  end
  local pic = pkg_data.ItemCfg.setpic
  if is_cloth then
    item_module:set_item_icon_sprite(self._img_pic_cloth, pic, self:get_load_proxy(), self._img_pic_prismatic)
  else
    UIUtil.set_image(self._img_pic_furniture, pic, self:get_load_proxy())
    if not_null(self._img_pic_prismatic) then
      self._img_pic_prismatic.sprite = nil
    end
  end
end

function M:_get_package_id(item_data)
  if item_data.Type == CodexDataType.Furniture then
    return item_data.FurnitureCfg and item_data.FurnitureCfg.packageid or 0
  elseif item_data.Type == CodexDataType.Cloth then
    return item_data.outfitsCfg and item_data.outfitsCfg.setid or 0
  end
  return 0
end

function M:_on_btn_package()
  if self._package_id == 0 then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  local pkg_data = codex_module:get_data_by_id(self._package_id)
  local package_name = pkg_data and pkg_data.IdCfg and pkg_data.IdCfg.name or ""
  popup:set_texts(UIUtil.get_text_by_id("Codex_JumpToPackageConfirm", package_name), UIUtil.get_text_by_id("Codex_Confirm"), UIUtil.get_text_by_id("Codex_Cancel"), nil)
  popup:set_callbacks(function()
    self:_goto_package()
  end)
  popup:show()
end

function M:_goto_package()
  local strategy = codex_module:get_type_view_strategy(self.holder.item_data.Type)
  local class_path = strategy:get_detail_page_class()
  local window = UIManagerInstance:get_window_by_class(class_path)
  local data = {
    item_id = self._package_id,
    enter_type = window and codex_module.codex_page_enter_type.item_detail_dialog or codex_module.codex_page_enter_type.codex_sub_type_list
  }
  if window then
    window:set_extra_data(data)
    window:refresh()
  else
    UIManagerInstance:open(class_path, data)
  end
end

return M
