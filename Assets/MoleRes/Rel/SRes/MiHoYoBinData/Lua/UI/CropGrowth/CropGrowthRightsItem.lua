local M = G.Class("CropGrowthRightsItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._rights_id = 0
  self._rights_cfg = nil
  self._unlocked = false
  self._jump_module_id = 0
  self._jump_group_id = 0
  self._jump_tutorial_id = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_help, pack(self, M._on_help_click))
end

function M:refresh(rights_id, unlocked)
  self._rights_id = rights_id or 0
  self._unlocked = unlocked == true
  self._rights_cfg = crop_growth_module:get_rights_cfg(rights_id)
  if self._rights_cfg == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._jump_module_id = 0
  self._jump_group_id = 0
  self._jump_tutorial_id = 0
  if string.is_valid(self._rights_cfg.rightsjumpguide) then
    local guide_parts = lua_str_split(self._rights_cfg.rightsjumpguide, ",", true)
    self._jump_module_id = tonumber(guide_parts[1]) or 0
    self._jump_group_id = tonumber(guide_parts[2]) or 0
    self._jump_tutorial_id = tonumber(guide_parts[3]) or 0
  end
  local text_params = crop_growth_module:get_rights_text_params(self._rights_cfg)
  UIUtil.set_text_by_id(self._txt, self._rights_cfg.rightstext, table.unpack(text_params))
  if string.is_valid(self._rights_cfg.rightsicon) then
    UIUtil.set_image(self._img_icon, self._rights_cfg.rightsicon, self:get_load_proxy())
  end
  self._state_group:SetState(self._unlocked and 1 or 0)
  self._state_group_help:SetState(0 < self._jump_module_id and 0 or 1)
end

function M:_on_help_click()
  if self._jump_module_id <= 0 then
    return
  end
  tutorial_module:open_tutorial_handbook_page_with_tutorial_id(self._jump_module_id, self._jump_group_id, self._jump_tutorial_id)
end

return M
