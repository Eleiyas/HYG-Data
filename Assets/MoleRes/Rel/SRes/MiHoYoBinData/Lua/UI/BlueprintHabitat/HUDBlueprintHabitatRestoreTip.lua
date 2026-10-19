local M = G.Class("HUDBlueprintHabitatRestoreTip", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local default_show_time = 3.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintHabitatInfoTips"
  self._habitat_id = 0
  self._creature_id = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:start_close_timer(default_show_time)
  local extra_data = self:get_extra_data()
  self._habitat_id = extra_data ~= nil and extra_data.habitat_id or 0
  self:_refresh_habitat()
  self:_refresh_creature()
end

function M:_refresh_habitat()
  if self._habitat_id == 0 then
    return
  end
  local ui_cfg = blueprint_habitat_module:get_habitat_ui_cfg(self._habitat_id)
  if ui_cfg == nil then
    return
  end
  UIUtil.set_text_by_id(self._txt_info, "Habitat_FinishTips", ui_cfg.name)
  UIUtil.set_image(self._img_icon, ui_cfg.icon, self:get_load_proxy())
end

function M:_refresh_creature()
  local creature_id = blueprint_habitat_module:get_habitat_creature_id(self._habitat_id)
  if creature_id == 0 then
    self:_set_creature_info_active(false)
    return
  end
  local item_cfg = item_module:get_cfg_by_id(creature_id)
  if item_cfg == nil then
    self:_set_creature_info_active(false)
    return
  end
  self:_set_creature_info_active(true)
  UIUtil.set_text_by_id(self._txt_creature, "Habitat_AnimalAppearTips", item_cfg.name)
  UIUtil.set_image(self._img_creature_icon, item_cfg.icon, self:get_load_proxy())
end

function M:_set_creature_info_active(active)
  UIUtil.set_active(self._txt_creature, active)
  UIUtil.set_active(self._img_creature_icon, active)
end

return M
