local JUMP_ITEM_CLS = "UI/CommonUI/CommonMissionJumpItem"
local M = G.Class("CommonMissionJumpDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonMissionJumpDialog"
  self.config.type = EUIType.Dialog
  self._task_ids = {}
  self._is_or = false
  self._jump_items = {}
  self._list_item = nil
  self._btn_close_1 = nil
  self._btn_close_2 = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  local ctx = self:get_extra_data() or {}
  self._task_ids = ctx.task_ids or {}
  self._is_or = ctx.is_or == true
  self:_refresh_or_state()
  self:_refresh_task_list()
end

function M:_refresh_or_state()
  if is_null(self._state_group) then
    return
  end
  self._state_group:SetState(self._is_or and 1 or 0)
end

function M:on_destroy()
  self._jump_items = {}
  self._task_ids = {}
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not_null(self._btn_close_1) then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_1)
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_close_1) then
    self:bind_close_btn(self._btn_close_1)
  end
  if not_null(self._btn_close_2) then
    self:bind_close_btn(self._btn_close_2)
  end
end

function M:_refresh_task_list()
  local task_ids = self._task_ids or {}
  for index = 1, #task_ids do
    local item = self._jump_items[index]
    if item == nil then
      item = self:_create_jump_item()
      self._jump_items[index] = item
    end
    if item ~= nil then
      item:set_active(true)
      item:set_data(task_ids[index])
    end
  end
  for i = #task_ids + 1, #self._jump_items do
    local item = self._jump_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
end

function M:_create_jump_item()
  if is_null(self._list_item) then
    return nil
  end
  local obj = self._list_item:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(JUMP_ITEM_CLS, obj)
end

return M
