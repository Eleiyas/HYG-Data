local M = G.Class("CookingMultipleConfirmDialog", G.UIWindow)
local base = G.UIWindow
local ingredient_item_cls = "UI/Cooking/CookingConfirmIngredientItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Cooking/CookingMultipleConfirmDialog"
  self.config.type = EUIType.Dialog
  self._item_entries = {}
  self._on_confirm = nil
  self._on_cancel = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._title_text = data.title_text or ""
  self._ingredients = data.ingredients or {}
  self._on_confirm = data.on_confirm
  self._on_cancel = data.on_cancel
  self:_refresh_content()
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
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_confim, pack(self, M._on_btn_confim_click))
end

function M:_on_btn_cancel_click()
  if self._on_cancel then
    self._on_cancel()
  end
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_confim_click()
  local confirm_cb = self._on_confirm
  UIManagerInstance:close(self.guid)
  if confirm_cb then
    confirm_cb()
  end
end

function M:_refresh_content()
  UIUtil.set_text(self._txt_title, self._title_text)
  self:_refresh_ingredient_list()
end

function M:_refresh_ingredient_list()
  local binder = self._list_item_content
  if is_null(binder) then
    Logger.LogError("[CookingMultipleConfirmDialog] _list_item_content is nil")
    return
  end
  local ingredients = self._ingredients or {}
  local count = #ingredients
  for i = 1, count do
    local data = ingredients[i]
    local entry = self._item_entries[i]
    if entry == nil then
      local obj = binder:AddItem(0)
      if not is_null(obj) then
        local panel = self:add_panel(ingredient_item_cls, obj)
        entry = {obj = obj, panel = panel}
        self._item_entries[i] = entry
      end
    end
    if entry and not is_null(entry.obj) and entry.panel then
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_data(data)
    end
  end
  for i = count + 1, #self._item_entries do
    local entry = self._item_entries[i]
    if entry and not is_null(entry.obj) then
      UIUtil.set_active(entry.obj, false)
    end
  end
end

return M
