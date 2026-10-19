local M = G.Class("HUDBlueprintHabitatDiscoverTip", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local default_show_time = 3.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintHabitatTip"
  self._is_habitat = true
  self._id = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
  self:start_close_timer(default_show_time)
  local extra_data = self:get_extra_data()
  if extra_data == nil then
    self._is_habitat = true
  else
    self._is_habitat = extra_data.is_habitat
  end
  self._id = extra_data ~= nil and extra_data.id or 0
  self._icon = extra_data ~= nil and extra_data.icon or nil
  if self._is_habitat then
    self._state_group_type:SetState(0)
    self:_refresh_habitat_info()
  else
    self._state_group_type:SetState(1)
    self:_refresh_blueprint_info()
  end
end

function M:_refresh_habitat_info()
  if self._id == 0 then
    return
  end
  local ui_cfg = blueprint_habitat_module:get_habitat_ui_cfg(self._id)
  if not ui_cfg then
    return
  end
  UIUtil.set_image(self._img_icon_dynamic, ui_cfg.icon, self:get_load_proxy())
end

function M:_refresh_blueprint_info()
  if self._id == 0 then
    return
  end
  UIUtil.set_image(self._img_icon_dynamic, self._icon, self:get_load_proxy())
end

function M:bind_callbacks()
  self:bind_callback(self._btn, function()
    if self._id == 0 then
      return
    end
    if CsPerformanceManagerUtil.IsPerformanceShowing() then
      return
    end
    if self._is_habitat then
      blueprint_habitat_module:open_habitat_info_page(self._id)
    else
      UIManagerInstance:open("UI/BlueprintHabitat/BlueprintInfoPage", {
        blueprint_id = self._id
      })
    end
    self:close_self()
  end)
end

return M
