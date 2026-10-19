local M = G.Class("HabitatSubPanel", G.UIPanel)
local base = G.UIPanel
local habitat_item_cls = "UI/BlueprintHabitat/Habitat/HabitatItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/habitatSubPanel"
end

function M:on_create()
  base.on_create(self)
  self._habitat_items = {}
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_habitat_list()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnHabitatDataChanged, function()
    self:_refresh_habitat_list()
  end)
end

function M:_refresh_habitat_list()
  local habitat_id_list = list_to_table(CsHabitatModuleUtil.GetAllDiscoveredHabitatId()) or {}
  for i = 1, #habitat_id_list do
    local habitat_id = habitat_id_list[i]
    local cls = self._habitat_items[i]
    if cls == nil then
      local obj = self._list_binder:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(habitat_item_cls, obj)
        self._habitat_items[i] = cls
        self:bind_callback(cls:get_btn(), function()
          self:_on_habitat_click(cls:get_habitat_id())
        end)
      end
    end
    cls:refresh(habitat_id)
  end
  for i = #habitat_id_list + 1, #self._habitat_items do
    local cls = self._habitat_items[i]
    if cls ~= nil then
      cls:refresh(nil)
    end
  end
end

function M:_on_habitat_click(habitat_id)
  self.holder:close_self()
  blueprint_habitat_module:open_habitat_info_page(habitat_id, true)
end

return M
